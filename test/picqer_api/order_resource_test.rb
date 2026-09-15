# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class OrderResourceTest < TestCase
    def test_looks_an_order_up_by_reference
      stub_picqer(:get, "orders", query: {"reference" => "skikoffer #360476", "offset" => "0"},
        body: [{idorder: 274848164, reference: "skikoffer #360476"}])

      assert_equal 274848164, client.orders.by_reference("skikoffer #360476").first.idorder
    end

    def test_returns_nothing_when_the_reference_does_not_match_rather_than_the_full_list
      stub_picqer(:get, "orders", query: {"reference" => "unknown", "offset" => "0"}, body: [])

      assert_empty client.orders.by_reference("unknown")
    end

    def test_rejects_filters_orders_does_not_support
      assert_raises(ArgumentError) { client.orders.all(idproduct: 1) }
    end
  end
end
