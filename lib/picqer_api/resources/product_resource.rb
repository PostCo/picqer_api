# frozen_string_literal: true

module PicqerAPI
  class ProductResource < Resource
    PATH = "products"

    SUPPORTED_FILTERS = %i[productcode search updated_after offset].freeze

    def find(idproduct)
      Objects::Product.new(get_request("#{PATH}/#{idproduct}"))
    end

    # `productcode` is an exact-match filter and is the SKU lookup. `search` is
    # fuzzy and must not be used for identity.
    #
    # Returns every match. A SKU is 1:1 with a variant only when Picqer's own
    # webshop connector imported the catalogue; with several matches or none, the
    # caller must route to manual review rather than guess.
    def by_productcode(productcode)
      all(productcode: productcode)
    end

    def list(**filters)
      assert_supported_filters!(filters, SUPPORTED_FILTERS)

      Objects::Product.new(get_request(PATH, params: filters))
    end

    def all(**filters)
      assert_supported_filters!(filters, SUPPORTED_FILTERS)

      Objects::Product.new(paginate(PATH, params: filters))
    end
  end
end
