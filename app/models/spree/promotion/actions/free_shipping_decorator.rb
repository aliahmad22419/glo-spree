module Spree
  class Promotion
    module Actions
      module FreeShippingDecorator
        def perform(payload = {})
          order = payload[:order]

          create_unique_adjustments(order, order.shipments) do |shipment|
            promotion.shipment_actionable?(order, shipment)
          end
        end

        def compute_amount(shipment)
          shipment.cost * -1
        end
      end
    end
  end
end

::Spree::Promotion::Actions::FreeShipping.prepend Spree::Promotion::Actions::FreeShippingDecorator
