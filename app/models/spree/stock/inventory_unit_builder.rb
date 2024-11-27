module Spree
  module Stock
    class InventoryUnitBuilder
      def initialize(order)
        @order = order
      end

      def units
        units_are = []
        @order.line_items.where(delivery_mode: FOOD_TYPES).group_by{|e| [e.vendor_name, e.delivery_mode, e.shipping_category, e.product&.effective_date.to_s]}.each do |vendor_name, line_items|
          units_are << unit_maker(line_items)
        end
        @order.line_items.where.not(delivery_mode: FOOD_TYPES).group_by{|e| [e.vendor_name, e.delivery_mode]}.each do |vendor_name, line_items|
          delivery_mode = vendor_name[1]
          if DIGITAL_TYPES.include?(delivery_mode)
            line_items.map do |line_item|
              line_unit = []
              line_unit << Spree::InventoryUnit.new(
                  pending: true,
                  line_item_id: line_item.id,
                  variant_id: line_item.variant_id,
                  quantity: line_item.quantity,
                  order_id: @order.id
              # vendor_id: vendor_id
              )
              units_are << line_unit
            end
          else
            units_are << unit_maker(line_items)
          end
        end
        units_are
      end

      def unit_maker line_items
        vendor_units = []
        line_items.map do |line_item|
          vendor_units << Spree::InventoryUnit.new(
              pending: true,
              line_item_id: line_item.id,
              variant_id: line_item.variant_id,
              quantity: line_item.quantity,
              order_id: @order.id
          # vendor_id: vendor_id
          )
        end
        return vendor_units
      end
    end
  end
end
