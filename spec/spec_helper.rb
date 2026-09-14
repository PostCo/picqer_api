# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "picqer_api"
require "webmock/rspec"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end

module ClientHelpers
  BASE_URL = "https://acme.picqer.com/api/v1"

  def build_client(**overrides)
    PicqerAPI::Client.new(
      subdomain: "acme",
      api_key: "test-key",
      sleeper: ->(_seconds) {},
      **overrides
    )
  end

  def stub_picqer(method, path, status: 200, body: {}, headers: {}, query: nil)
    request = stub_request(method, "#{BASE_URL}/#{path}")
    request = request.with(query: query || hash_including({}))
    request.to_return(
      status: status,
      body: body.is_a?(String) ? body : JSON.dump(body),
      headers: {"Content-Type" => "application/json"}.merge(headers)
    )
  end
end

RSpec.configure { |config| config.include ClientHelpers }
