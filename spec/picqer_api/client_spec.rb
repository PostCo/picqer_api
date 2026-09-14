# frozen_string_literal: true

RSpec.describe PicqerAPI::Client do
  it "builds the base URL from the subdomain" do
    expect(build_client.base_url).to eq("https://mendex.picqer.com/api/v1/")
  end

  it "requires a subdomain and an API key" do
    expect { described_class.new(subdomain: " ", api_key: "k") }.to raise_error(ArgumentError)
    expect { described_class.new(subdomain: "mendex", api_key: "") }.to raise_error(ArgumentError)
  end

  it "sends the API key as the HTTP Basic username with an empty password" do
    request = stub_picqer(:get, "warehouses", body: [])

    build_client.warehouses.all

    expect(request.with(headers: {"Authorization" => "Basic #{Base64.strict_encode64("test-key:")}"})).to have_been_made
  end

  it "sends a User-Agent, which Picqer requires" do
    request = stub_picqer(:get, "warehouses", body: [])

    build_client(user_agent: "PostCo/1.0").warehouses.all

    expect(request.with(headers: {"User-Agent" => "PostCo/1.0"})).to have_been_made
  end

  it "records the rate-limit headers from the last response" do
    stub_picqer(:get, "warehouses", body: [], headers: {"X-RateLimit-Limit" => "500", "X-RateLimit-Remaining" => "498"})

    client = build_client
    client.warehouses.all

    expect(client.rate_limit.limit).to eq(500)
    expect(client.rate_limit.remaining).to eq(498)
    expect(client.rate_limit).not_to be_exhausted
  end
end
