# frozen_string_literal: true

module PicqerAPI
  class WarehouseResource < Resource
    PATH = "warehouses"

    # Warehouse is a payload field, not credential scope: one key covers every
    # warehouse on the account. Ask here at connect time instead of configuring it
    # by hand — one warehouse means no choice to make, several means a picker.
    def all
      Objects::Warehouse.new(paginate(PATH))
    end
  end
end
