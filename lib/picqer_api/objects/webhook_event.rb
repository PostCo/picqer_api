# frozen_string_literal: true

require "json"

module PicqerAPI
  module Objects
    # Payload shapes differ between events: `returns.created` and
    # `returns.changed` put the return flat in `data`, while
    # `returns.status_changed` wraps it as `data.return` plus `data.return_log`.
    # This normalises both so one handler can read them.
    class WebhookEvent < Base
      # The return itself, whichever shape it arrived in.
      def return_data
        payload = data
        return unless payload

        (payload.respond_to?(:return) && payload.return) ? payload.return : payload
      end

      def return_log
        data&.return_log
      end

      def idreturn
        return_data&.idreturn
      end

      def idreturn_status
        return_data&.idreturn_status
      end

      # Picqer stamps both events of one change with the same `updated_at`, which
      # makes (idreturn, updated_at) usable as an idempotency key.
      def updated_at
        return_data&.updated_at
      end

      def returned_products
        Array(return_data&.returned_products)
      end

      # `status_changed` or `received_products`. Branch on this, not on {#event},
      # because a receive also arrives as `returns.status_changed` with the
      # return-level status unchanged.
      def log_type
        return_log&.type
      end

      def received_products?
        log_type == Webhook::LOG_TYPE_RECEIVED_PRODUCTS
      end

      # The Picqer user behind the write, present only on `returns.status_changed`.
      # It is the only origin signal available, so a write made by this
      # integration's own key can be told from the warehouse's work here and
      # nowhere else. `returns.changed` carries no actor at all and also fires on
      # status changes, so it cannot be loop-guarded by origin.
      def iduser
        return_log&.iduser
      end

      # Set by Picqer on create for a fulfilment-scoped key; proves which customer
      # the event belongs to.
      def idfulfilment_customer
        return_data&.idfulfilment_customer
      end
    end
  end
end
