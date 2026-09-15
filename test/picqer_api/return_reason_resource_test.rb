# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ReturnReasonResourceTest < TestCase
    def test_returns_the_accounts_reasons
      stub_picqer(:get, "return_reasons", body: [{idreturn_reason: 13593, name: "Wrong product"}])

      assert_equal 13593, client.return_reasons.all.first.idreturn_reason
    end
  end
end
