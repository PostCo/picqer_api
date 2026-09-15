# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class WebhookTest < TestCase
    SECRET = "s3cret"

    def payload
      @payload ||= JSON.dump({event: "returns.changed", data: {idreturn: 6943824}})
    end

    def test_accepts_base64_hmac_sha256_of_the_raw_body
      signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", SECRET, payload))

      assert Webhook.valid_signature?(payload: payload, signature: signature, secret: SECRET)
    end

    def test_rejects_a_wrong_secret_a_wrong_body_and_a_malformed_signature
      signature = Webhook.signature(payload, SECRET)

      refute Webhook.valid_signature?(payload: payload, signature: signature, secret: "other")
      refute Webhook.valid_signature?(payload: "{}", signature: signature, secret: SECRET)
      refute Webhook.valid_signature?(payload: payload, signature: "nope", secret: SECRET)
      refute Webhook.valid_signature?(payload: payload, signature: nil, secret: SECRET)
    end

    def test_reads_the_flat_shape_of_created_and_changed
      event = Webhook.parse(JSON.dump({
        event: "returns.created",
        data: {idreturn: 6943824, idreturn_status: 17267, updated_at: "2026-09-14 05:22:59",
               idfulfilment_customer: 10809, returned_products: [{idreturn_product: 1, status: "expected"}]}
      }))

      assert_equal 6943824, event.idreturn
      assert_equal 17267, event.idreturn_status
      assert_equal "2026-09-14 05:22:59", event.updated_at
      assert_equal 10809, event.idfulfilment_customer
      assert_equal "expected", event.returned_products.first.status
      assert_nil event.iduser
    end

    def test_reads_the_nested_shape_of_status_changed_and_exposes_the_actor
      event = Webhook.parse({
        "event" => "returns.status_changed",
        "data" => {
          "return" => {"idreturn" => 6943824, "idreturn_status" => 17272, "updated_at" => "2026-09-14 05:22:59"},
          "return_log" => {"iduser" => 42675, "type" => "status_changed", "message" => "..."}
        }
      })

      assert_equal 6943824, event.idreturn
      assert_equal 17272, event.idreturn_status
      assert_equal "status_changed", event.log_type
      assert_equal 42675, event.iduser
      refute_predicate event, :received_products?
    end

    def test_tells_a_receive_apart_from_a_real_status_change_on_the_same_event_name
      event = Webhook.parse({
        "event" => "returns.status_changed",
        "data" => {
          "return" => {"idreturn" => 6943824, "idreturn_status" => 17267,
                       "returned_products" => [{"idreturn_product" => 1, "status" => "added_to_stock"}]},
          "return_log" => {"type" => "received_products"}
        }
      })

      assert_predicate event, :received_products?
      assert_equal "added_to_stock", event.returned_products.first.status
    end
  end
end
