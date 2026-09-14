# frozen_string_literal: true

RSpec.describe "vocabulary resources" do
  let(:client) { build_client }

  describe PicqerAPI::ReturnStatusResource do
    it "returns the account's statuses and isolates the completed ones" do
      stub_picqer(:get, "return_statuses", body: [
        {idreturn_status: 17267, name: "Received", default: false, completed: false},
        {idreturn_status: 17268, name: "Completed", default: false, completed: true}
      ])

      statuses = client.return_statuses.all

      expect(statuses.map(&:name)).to eq(["Received", "Completed"])
      # `default` is not dependable: an account was observed with none set.
      expect(client.return_statuses.completed.map(&:idreturn_status)).to eq([17268])
    end
  end

  describe PicqerAPI::ReturnReasonResource do
    it "returns the account's reasons" do
      stub_picqer(:get, "return_reasons", body: [{idreturn_reason: 13593, name: "Wrong product"}])

      expect(client.return_reasons.all.first.idreturn_reason).to eq(13593)
    end
  end

  describe PicqerAPI::WarehouseResource do
    it "returns the warehouses the key can reach" do
      stub_picqer(:get, "warehouses", body: [{idwarehouse: 13910, name: "Weesp"}])

      expect(client.warehouses.all.first.name).to eq("Weesp")
    end
  end

  describe PicqerAPI::ProductResource do
    it "looks a SKU up with the exact productcode filter" do
      stub_picqer(:get, "products", query: {"productcode" => "LC808899", "offset" => "0"},
        body: [{idproduct: 51654384, productcode: "LC808899"}])

      expect(client.products.by_productcode("LC808899").first.idproduct).to eq(51654384)
    end

    it "rejects filters products does not support" do
      expect { client.products.all(barcode: "123") }.to raise_error(ArgumentError)
    end
  end

  describe PicqerAPI::OrderResource do
    it "looks an order up by reference" do
      stub_picqer(:get, "orders", query: {"reference" => "skikoffer #360476", "offset" => "0"},
        body: [{idorder: 274848164, reference: "skikoffer #360476"}])

      expect(client.orders.by_reference("skikoffer #360476").first.idorder).to eq(274848164)
    end
  end

  describe PicqerAPI::HookResource do
    it "creates a hook with a secret" do
      request = stub_picqer(:post, "hooks", status: 201, body: {idhook: 67982, active: true})

      hook = client.hooks.create(name: "PostCo", event: "returns.status_changed",
        address: "https://example.test/hooks", secret: "s3cret")

      expect(hook.idhook).to eq(67982)
      expect(request.with { |req| JSON.parse(req.body)["secret"] == "s3cret" }).to have_been_made
    end

    it "treats DELETE as a deactivation and can reactivate" do
      stub_picqer(:delete, "hooks/67982", status: 204, body: "")
      stub_picqer(:post, "hooks/67982/reactivate", status: 200, body: {idhook: 67982, active: true})

      expect(client.hooks.deactivate(67982)).to be(true)
      expect(client.hooks.reactivate(67982).active).to be(true)
    end
  end
end
