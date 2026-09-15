# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class WarehouseResourceTest < TestCase
    def test_returns_the_warehouses_the_key_can_reach
      stub_picqer(:get, "warehouses", body: [{idwarehouse: 13910, name: "Weesp"}])

      assert_equal "Weesp", client.warehouses.all.first.name
    end
  end
end
