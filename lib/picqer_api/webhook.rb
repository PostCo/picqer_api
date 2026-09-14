# frozen_string_literal: true

require "base64"
require "json"
require "openssl"

module PicqerAPI
  # Inbound half of the integration. Picqer signs every delivery; verify before
  # parsing, and remember that one status change arrives as two events.
  module Webhook
    SIGNATURE_HEADER = "X-Picqer-Signature"

    CREATED = "returns.created"
    CHANGED = "returns.changed"
    STATUS_CHANGED = "returns.status_changed"
    PRODUCTS_RECEIVED = "returns.products_received"

    # `returns.status_changed` carries two different meanings, told apart by the
    # log type rather than the event name.
    LOG_TYPE_STATUS_CHANGED = "status_changed"
    LOG_TYPE_RECEIVED_PRODUCTS = "received_products"

    module_function

    # Base64 of HMAC-SHA256 over the raw request body, keyed with the secret given
    # at hook registration. Compare in constant time, and verify before parsing.
    def signature(payload, secret)
      Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret.to_s, payload.to_s))
    end

    def valid_signature?(payload:, signature:, secret:)
      expected = signature(payload, secret)
      given = signature.to_s

      return false unless expected.bytesize == given.bytesize

      OpenSSL.fixed_length_secure_compare(expected, given)
    end

    # @return [Objects::WebhookEvent]
    def parse(payload)
      body = payload.is_a?(String) ? JSON.parse(payload) : payload

      Objects::WebhookEvent.new(body)
    end
  end
end
