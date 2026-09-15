# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ReturnStatusResourceTest < TestCase
    STATUSES = [
      {idreturn_status: 17267, name: "Received", default: false, completed: false},
      {idreturn_status: 17268, name: "Completed", default: false, completed: true}
    ].freeze

    def test_returns_the_accounts_statuses
      stub_picqer(:get, "return_statuses", body: STATUSES)

      assert_equal ["Received", "Completed"], client.return_statuses.all.map(&:name)
    end

    def test_isolates_the_completed_statuses_the_only_dependable_marker
      stub_picqer(:get, "return_statuses", body: STATUSES)

      # `default` is not dependable: an account was observed with it set on nothing.
      assert_equal [17268], client.return_statuses.completed.map(&:idreturn_status)
    end
  end
end
