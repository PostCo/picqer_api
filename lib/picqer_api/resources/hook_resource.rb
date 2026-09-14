# frozen_string_literal: true

module PicqerAPI
  class HookResource < Resource
    PATH = "hooks"

    # A customer-scoped key can register its own hooks, and sees only its own in
    # {#all}. Events from the provider's own staff still reach them.
    def all
      Objects::Hook.new(paginate(PATH))
    end

    def find(idhook)
      Objects::Hook.new(get_request("#{PATH}/#{idhook}"))
    end

    # @param secret [String] the HMAC key Picqer signs deliveries with. Keep it;
    #   it is needed by {Webhook.valid_signature?} and cannot be read back.
    def create(name:, event:, address:, secret:)
      body = {"name" => name, "event" => event, "address" => address, "secret" => secret}

      Objects::Hook.new(post_request(PATH, body: body))
    end

    # DELETE deactivates rather than deletes: the row persists with
    # `active: false` and can be revived. Provisioning must reuse an existing
    # inactive hook instead of accumulating duplicates on every reconnect.
    def deactivate(idhook)
      delete_request("#{PATH}/#{idhook}")
      true
    end

    def reactivate(idhook)
      Objects::Hook.new(post_request("#{PATH}/#{idhook}/reactivate"))
    end
  end
end
