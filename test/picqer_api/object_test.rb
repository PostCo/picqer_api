# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ObjectTest < TestCase
    def test_wraps_an_array_of_hashes_into_an_array_of_objects
      objects = Base.new([{idreturn: 1}, {idreturn: 2}])

      assert_equal [1, 2], objects.map(&:idreturn)
    end

    def test_exposes_nested_structures_and_keeps_the_raw_response
      attributes = {"idreturn" => 1, "returned_products" => [{"idreturn_product" => 9}]}
      object = Base.new(attributes)

      assert_equal 9, object.returned_products.first.idreturn_product
      assert_equal attributes, object.raw
      assert_equal 1, object.to_h["idreturn"]
    end
  end
end
