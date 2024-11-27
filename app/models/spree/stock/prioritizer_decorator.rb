module Spree
  module Stock
    module PrioritizerDecorator
      def hash_item(item)
        shipment = item.inventory_unit.shipment
        variant  = item.line_item

        if shipment.present?
          variant.hash ^ shipment.hash
        else
          if item.line_item.delivery_mode == "food_pickup"
            variant.hash + 1
          else
            variant.hash
          end
        end
      end
    end
  end
end

::Spree::Stock::Prioritizer.prepend(Spree::Stock::PrioritizerDecorator)
