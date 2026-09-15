# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ClientTest < TestCase
    def test_builds_the_base_url_from_the_subdomain
      assert_equal "https://acme.picqer.com/api/v1/", build_client.base_url
    end

    def test_requires_a_subdomain_and_an_api_key
      assert_raises(ArgumentError) { Client.new(subdomain: " ", api_key: "k") }
      assert_raises(ArgumentError) { Client.new(subdomain: "acme", api_key: "") }
    end

    def test_sends_the_api_key_as_the_basic_username_with_an_empty_password
      stub_picqer(:get, "warehouses", body: [])

      build_client.warehouses.all

      assert_requested(:get, "#{BASE_URL}/warehouses?offset=0",
        headers: {"Authorization" => "Basic #{Base64.strict_encode64("test-key:")}"})
    end

    def test_sends_a_user_agent_which_picqer_requires
      stub_picqer(:get, "warehouses", body: [])

      build_client(user_agent: "PostCo/1.0").warehouses.all

      assert_requested(:get, "#{BASE_URL}/warehouses?offset=0", headers: {"User-Agent" => "PostCo/1.0"})
    end

    def test_records_the_rate_limit_headers_from_the_last_response
      stub_picqer(:get, "warehouses", body: [],
        headers: {"X-RateLimit-Limit" => "500", "X-RateLimit-Remaining" => "498"})

      client.warehouses.all

      assert_equal 500, client.rate_limit.limit
      assert_equal 498, client.rate_limit.remaining
      refute_predicate client.rate_limit, :exhausted?
    end
  end
end
