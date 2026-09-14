# frozen_string_literal: true

RSpec.describe PicqerAPI::ReturnResource do
  let(:client) { build_client }

  describe "#create" do
    it "posts the payload and returns the response object" do
      request = stub_picqer(:post, "returns", status: 201,
        body: {idreturn: 6943828, returnid: "R2026-1030",
               returned_products: [{idreturn_product: 11196084, idproduct: 51654384}]})

      result = client.returns.create({idreturn_status: 17267, reference: "RMA-12345"})

      expect(result.idreturn).to eq(6943828)
      expect(result.returned_products.first.idreturn_product).to eq(11196084)
      expect(request.with(body: {"idreturn_status" => 17267, "reference" => "RMA-12345"})).to have_been_made
    end

    it "strips non-BMP characters and truncates the varchar(255) fields" do
      request = stub_picqer(:post, "returns", status: 201, body: {idreturn: 1})

      client.returns.create({idreturn_status: 17267, name: "Anna 😀 Smith", address: "a" * 300})

      expect(request.with { |req|
        body = JSON.parse(req.body)
        body["name"] == "Anna Smith" && body["address"].length == 255
      }).to have_been_made
    end

    it "leaves the payload alone when sanitizing is turned off" do
      request = stub_picqer(:post, "returns", status: 201, body: {idreturn: 1})

      client.returns.create({idreturn_status: 17267, name: "Anna 😀 Smith"}, sanitize: false)

      expect(request.with { |req| JSON.parse(req.body)["name"] == "Anna 😀 Smith" }).to have_been_made
    end

    it "does not touch non-string fields" do
      request = stub_picqer(:post, "returns", status: 201, body: {idreturn: 1})

      client.returns.create({idreturn_status: 17267, returned_products: [{idproduct: 1, idreturn_reason: 13593}]})

      expect(request.with { |req| JSON.parse(req.body)["returned_products"].first["idproduct"] == 1 }).to have_been_made
    end
  end

  describe "#list" do
    it "rejects filters Picqer would silently ignore" do
      expect { client.returns.list(reference: "RMA-12345") }
        .to raise_error(ArgumentError, /unsupported filter\(s\) reference/)
      expect { client.returns.list(idorder: 274848164) }.to raise_error(ArgumentError)
    end

    it "allows the filters Picqer honours" do
      stub_picqer(:get, "returns", query: {"status" => "completed"}, body: [{idreturn: 1}])

      expect(client.returns.list(status: "completed").first.idreturn).to eq(1)
    end
  end

  describe "#search" do
    it "passes the fuzzy query through and paginates" do
      stub_picqer(:get, "returns", query: {"search" => "RMA-12345", "offset" => "0"},
        body: [{idreturn: 1, reference: "RMA-12345"}, {idreturn: 2, reference: "RMA-12345-B"}])

      rows = client.returns.search("RMA-12345")

      # Deliberately returns both: the caller verifies `reference` exactly and
      # decides what zero, one or several matches mean.
      expect(rows.map(&:idreturn)).to eq([1, 2])
    end
  end

  describe "#add_log" do
    it "posts a status change and truncates the message to the text column" do
      request = stub_picqer(:post, "returns/1/logs", status: 201, body: {idreturn_log: 9})

      client.returns.add_log(1, idreturn_status: 17272, message: "a" * 70_000)

      expect(request.with { |req|
        body = JSON.parse(req.body)
        body["idreturn_status"] == 17272 && body["message"].length == 65_535
      }).to have_been_made
    end
  end

  describe "#receive" do
    it "surfaces the fulfilment capability gap as NotAccessibleError" do
      stub_picqer(:post, "returns/1/receive", status: 400,
        body: {error: true, error_code: 31, error_message: "Function not accessible for fulfilment"})

      expect {
        client.returns.receive(1, idwarehouse: 13910, returned_products: [{idreturn_product: 2, status: "added_to_stock"}])
      }.to raise_error(PicqerAPI::NotAccessibleError)
    end
  end

  describe "#delete_returned_product" do
    it "deletes a line" do
      stub_picqer(:delete, "returns/1/returned_products/2", status: 204, body: "")

      expect(client.returns.delete_returned_product(1, 2)).to be(true)
    end
  end
end
