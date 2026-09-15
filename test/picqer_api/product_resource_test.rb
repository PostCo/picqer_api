# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ProductResourceTest < TestCase
    def test_looks_a_sku_up_with_the_exact_productcode_filter
      stub_picqer(:get, "products", query: {"productcode" => "LC808899", "offset" => "0"},
        body: [{idproduct: 51654384, productcode: "LC808899"}])

      assert_equal 51654384, client.products.by_productcode("LC808899").first.idproduct
    end

    def test_returns_every_match_rather_than_picking_one
      stub_picqer(:get, "products", query: {"productcode" => "LC808899", "offset" => "0"},
        body: [{idproduct: 1, productcode: "LC808899"}, {idproduct: 2, productcode: "LC808899"}])

      assert_equal [1, 2], client.products.by_productcode("LC808899").map(&:idproduct)
    end

    def test_rejects_filters_products_does_not_support
      assert_raises(ArgumentError) { client.products.all(barcode: "123") }
    end

    def test_fetches_one_product_by_id
      stub_picqer(:get, "products/51654384", body: {idproduct: 51654384, productcode: "LC808899"})

      assert_equal "LC808899", client.products.find(51654384).productcode
    end
  end
end
