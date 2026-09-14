# frozen_string_literal: true

module PicqerAPI
  class OrderResource < Resource
    PATH = "orders"

    SUPPORTED_FILTERS = %i[orderid reference status search updated_after offset].freeze

    def find(idorder)
      Objects::Order.new(get_request("#{PATH}/#{idorder}"))
    end

    # Unlike returns, order filters are honoured and exact — `orderid` matches the
    # whole value, not a prefix.
    #
    # Which field carries the webshop order name is a connector convention rather
    # than a Picqer guarantee (observed on `reference`), so verify per account and
    # treat the lookup as best-effort: a bad `idorder` is fatal to a return create,
    # while a null one is normal.
    def by_reference(reference)
      all(reference: reference)
    end

    def list(**filters)
      assert_supported_filters!(filters, SUPPORTED_FILTERS)

      Objects::Order.new(get_request(PATH, params: filters))
    end

    def all(**filters)
      assert_supported_filters!(filters, SUPPORTED_FILTERS)

      Objects::Order.new(paginate(PATH, params: filters))
    end
  end
end
