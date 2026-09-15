# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class HookResourceTest < TestCase
    def test_creates_a_hook_with_a_secret
      stub_picqer(:post, "hooks", status: 201, body: {idhook: 67982, active: true})

      hook = client.hooks.create(name: "PostCo", event: "returns.status_changed",
        address: "https://example.test/hooks", secret: "s3cret")

      assert_equal 67982, hook.idhook
      assert_requested(:post, "#{BASE_URL}/hooks") { |request| JSON.parse(request.body)["secret"] == "s3cret" }
    end

    def test_lists_the_hooks_the_key_owns
      stub_picqer(:get, "hooks", body: [{idhook: 67982, active: false}])

      assert_equal false, client.hooks.all.first.active
    end

    def test_treats_delete_as_a_deactivation_and_can_reactivate
      stub_picqer(:delete, "hooks/67982", status: 204, body: "")
      stub_picqer(:post, "hooks/67982/reactivate", status: 200, body: {idhook: 67982, active: true})

      assert client.hooks.deactivate(67982)
      assert_equal true, client.hooks.reactivate(67982).active
    end
  end
end
