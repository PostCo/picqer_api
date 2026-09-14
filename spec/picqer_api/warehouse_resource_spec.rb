# frozen_string_literal: true

RSpec.describe PicqerAPI::WarehouseResource do
  it "returns the warehouses the key can reach" do
    stub_picqer(:get, "warehouses", body: [{idwarehouse: 13910, name: "Weesp"}])

    expect(build_client.warehouses.all.first.name).to eq("Weesp")
  end
end
