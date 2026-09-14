# frozen_string_literal: true

RSpec.describe PicqerAPI::OrderResource do
  let(:client) { build_client }

  it "looks an order up by reference" do
    stub_picqer(:get, "orders", query: {"reference" => "skikoffer #360476", "offset" => "0"},
      body: [{idorder: 274848164, reference: "skikoffer #360476"}])

    expect(client.orders.by_reference("skikoffer #360476").first.idorder).to eq(274848164)
  end

  it "returns nothing when the reference does not match, rather than the full list" do
    stub_picqer(:get, "orders", query: {"reference" => "unknown", "offset" => "0"}, body: [])

    expect(client.orders.by_reference("unknown")).to eq([])
  end

  it "rejects filters orders does not support" do
    expect { client.orders.all(idproduct: 1) }.to raise_error(ArgumentError)
  end
end
