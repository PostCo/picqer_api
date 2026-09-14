# frozen_string_literal: true

RSpec.describe PicqerAPI::Webhook do
  let(:secret) { "s3cret" }
  let(:payload) { JSON.dump({event: "returns.changed", data: {idreturn: 6943824}}) }

  describe ".valid_signature?" do
    it "accepts base64 HMAC-SHA256 of the raw body" do
      signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload))

      expect(described_class.valid_signature?(payload: payload, signature: signature, secret: secret)).to be(true)
    end

    it "rejects a wrong secret, a wrong body and a malformed signature" do
      signature = described_class.signature(payload, secret)

      expect(described_class.valid_signature?(payload: payload, signature: signature, secret: "other")).to be(false)
      expect(described_class.valid_signature?(payload: "{}", signature: signature, secret: secret)).to be(false)
      expect(described_class.valid_signature?(payload: payload, signature: "nope", secret: secret)).to be(false)
      expect(described_class.valid_signature?(payload: payload, signature: nil, secret: secret)).to be(false)
    end
  end

  describe ".parse" do
    it "reads the flat shape of returns.created and returns.changed" do
      event = described_class.parse(JSON.dump({
        event: "returns.created",
        data: {idreturn: 6943824, idreturn_status: 17267, updated_at: "2026-09-14 05:22:59",
               idfulfilment_customer: 10809, returned_products: [{idreturn_product: 1, status: "expected"}]}
      }))

      expect(event.idreturn).to eq(6943824)
      expect(event.idreturn_status).to eq(17267)
      expect(event.updated_at).to eq("2026-09-14 05:22:59")
      expect(event.idfulfilment_customer).to eq(10809)
      expect(event.returned_products.first.status).to eq("expected")
      expect(event.iduser).to be_nil
    end

    it "reads the nested shape of returns.status_changed and exposes the actor" do
      event = described_class.parse({
        "event" => "returns.status_changed",
        "data" => {
          "return" => {"idreturn" => 6943824, "idreturn_status" => 17272, "updated_at" => "2026-09-14 05:22:59"},
          "return_log" => {"iduser" => 42675, "type" => "status_changed", "message" => "..."}
        }
      })

      expect(event.idreturn).to eq(6943824)
      expect(event.idreturn_status).to eq(17272)
      expect(event.log_type).to eq("status_changed")
      expect(event.iduser).to eq(42675)
      expect(event).not_to be_received_products
    end

    it "tells a receive apart from a real status change on the same event name" do
      event = described_class.parse({
        "event" => "returns.status_changed",
        "data" => {
          "return" => {"idreturn" => 6943824, "idreturn_status" => 17267,
                       "returned_products" => [{"idreturn_product" => 1, "status" => "added_to_stock"}]},
          "return_log" => {"type" => "received_products"}
        }
      })

      expect(event).to be_received_products
      expect(event.returned_products.first.status).to eq("added_to_stock")
    end
  end
end
