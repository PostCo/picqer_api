# frozen_string_literal: true

RSpec.describe PicqerAPI::Base do
  it "wraps an array of hashes into an array of objects" do
    objects = described_class.new([{idreturn: 1}, {idreturn: 2}])

    expect(objects.map(&:idreturn)).to eq([1, 2])
  end

  it "exposes nested structures and keeps the raw response" do
    object = described_class.new({"idreturn" => 1, "returned_products" => [{"idreturn_product" => 9}]})

    expect(object.returned_products.first.idreturn_product).to eq(9)
    expect(object.raw).to eq({"idreturn" => 1, "returned_products" => [{"idreturn_product" => 9}]})
    expect(object.to_h["idreturn"]).to eq(1)
  end
end
