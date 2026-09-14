# frozen_string_literal: true

RSpec.describe PicqerAPI::ProductResource do
  let(:client) { build_client }

  it "looks a SKU up with the exact productcode filter" do
    stub_picqer(:get, "products", query: {"productcode" => "LC808899", "offset" => "0"},
      body: [{idproduct: 51654384, productcode: "LC808899"}])

    expect(client.products.by_productcode("LC808899").first.idproduct).to eq(51654384)
  end

  it "returns every match rather than picking one" do
    stub_picqer(:get, "products", query: {"productcode" => "LC808899", "offset" => "0"},
      body: [{idproduct: 1, productcode: "LC808899"}, {idproduct: 2, productcode: "LC808899"}])

    expect(client.products.by_productcode("LC808899").map(&:idproduct)).to eq([1, 2])
  end

  it "rejects filters products does not support" do
    expect { client.products.all(barcode: "123") }.to raise_error(ArgumentError)
  end

  it "fetches one product by id" do
    stub_picqer(:get, "products/51654384", body: {idproduct: 51654384, productcode: "LC808899"})

    expect(client.products.find(51654384).productcode).to eq("LC808899")
  end
end
