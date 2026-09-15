# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "picqer_api"
require "base64"
require "json"
require "openssl"
require "minitest/autorun"
require "webmock/minitest"

WebMock.disable_net_connect!

module PicqerAPI
  class TestCase < Minitest::Test
    BASE_URL = "https://acme.picqer.com/api/v1"

    def build_client(**overrides)
      PicqerAPI::Client.new(
        subdomain: "acme",
        api_key: "test-key",
        sleeper: ->(_seconds) {},
        **overrides
      )
    end

    def client
      @client ||= build_client
    end

    def stub_picqer(method, path, status: 200, body: {}, headers: {}, query: nil)
      stub_request(method, "#{BASE_URL}/#{path}")
        .with(query: query || hash_including({}))
        .to_return(
          status: status,
          body: body.is_a?(String) ? body : JSON.dump(body),
          headers: {"Content-Type" => "application/json"}.merge(headers)
        )
    end
  end
end
