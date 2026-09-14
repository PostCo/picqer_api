# frozen_string_literal: true

module PicqerAPI
  class ReturnResource < Resource
    PATH = "returns"

    # Measured: every other filter is accepted, ignored, and answered with the
    # full list and a 200. Passing anything outside this set raises.
    SUPPORTED_FILTERS = %i[search status emailaddress idcustomer created_after updated_after offset].freeze

    # utf8mb3 varchar(255) columns on the return header.
    STRING_FIELDS = %w[
      name contactname address address2 zipcode city region country
      telephone emailaddress language reference tracking_code
    ].freeze

    # @param attributes [Hash] the return payload. Only `idreturn_status` is
    #   actually required; `idtemplate` is documented as required and is not.
    #   Unknown keys are accepted, dropped, and answered with a 201.
    # @param sanitize [Boolean] strip non-BMP characters and truncate the
    #   varchar(255) header fields before sending. Picqer does both silently on
    #   its side; doing it here makes the loss visible to the caller.
    # @return [Objects::Return] the create response. Note that the response
    #   echoes the input rather than what was stored — read back with {#find}
    #   before trusting any field.
    def create(attributes, sanitize: true)
      body = sanitize ? sanitize_attributes(attributes) : stringify(attributes)

      Objects::Return.new(post_request(PATH, body: body))
    end

    def find(idreturn)
      Objects::Return.new(get_request("#{PATH}/#{idreturn}"))
    end

    # One page of at most 100 rows.
    def list(**filters)
      assert_supported_filters!(filters, SUPPORTED_FILTERS)

      Objects::Return.new(get_request(PATH, params: filters))
    end

    # Every page, walked by offset.
    def all(**filters)
      assert_supported_filters!(filters, SUPPORTED_FILTERS)

      Objects::Return.new(paginate(PATH, params: filters))
    end

    # Picqer's only usable free-text lookup. It is a fuzzy substring match with no
    # uniqueness guarantee, so it cannot answer "the return whose reference is X".
    # Verify `reference` exactly on the rows that come back and handle zero, one
    # and several matches separately before acting.
    def search(query, **filters)
      all(**filters, search: query)
    end

    def update(idreturn, attributes, sanitize: true)
      body = sanitize ? sanitize_attributes(attributes) : stringify(attributes)

      Objects::Return.new(put_request("#{PATH}/#{idreturn}", body: body))
    end

    # Not available once any line has been added to stock.
    def delete(idreturn)
      delete_request("#{PATH}/#{idreturn}")
      true
    end

    def logs(idreturn)
      Objects::ReturnLog.new(get_request("#{PATH}/#{idreturn}/logs"))
    end

    # Posting a log is how a return-level status change is made. It emits both
    # `returns.status_changed` and `returns.changed` webhooks.
    def add_log(idreturn, idreturn_status: nil, message: nil)
      body = {
        "idreturn_status" => idreturn_status,
        "message" => Text.sanitize_log_message(message)
      }.compact

      Objects::ReturnLog.new(post_request("#{PATH}/#{idreturn}/logs", body: body))
    end

    def delete_returned_product(idreturn, idreturn_product)
      delete_request("#{PATH}/#{idreturn}/returned_products/#{idreturn_product}")
      true
    end

    # Receiving is the warehouse's operation. A customer-scoped (fulfilment) key
    # gets 400 / error_code 31 here, raised as {NotAccessibleError}. Present for
    # accounts whose key owns the warehouse.
    #
    # @param returned_products [Array<Hash>] `{idreturn_product:, status:}` pairs,
    #   status being one of `expected`, `received`, `added_to_stock`, `unsalable`.
    def receive(idreturn, idwarehouse:, returned_products:)
      body = {"idwarehouse" => idwarehouse, "return_products" => stringify_each(returned_products)}

      Objects::Return.new(post_request("#{PATH}/#{idreturn}/receive", body: body))
    end

    private

    def sanitize_attributes(attributes)
      stringify(attributes).each_with_object({}) do |(key, value), result|
        result[key] = STRING_FIELDS.include?(key) ? Text.sanitize(value) : value
      end
    end

    def stringify(attributes)
      attributes.to_h.transform_keys(&:to_s)
    end

    def stringify_each(rows)
      Array(rows).map { |row| stringify(row) }
    end
  end
end
