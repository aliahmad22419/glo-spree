module Spree
  class Promotion
    module Rules
      class ShipmentProductsTotal < PromotionRule
        preference :product_type_limits, :array, default: []

        validate :unique_product_type

        def applicable?(promotable)
          return false unless promotable.is_a?(Spree::Order)
          promotion.actions.map(&:type).include?('Spree::Promotion::Actions::FreeShipping')
        end

        def eligible?(order, _options = {})
          item_types = order.shipments.map(&:delivery_mode).uniq
          eligible_limits = preferred_product_type_limits.select{|limit| item_types.include?(limit[:product_type]) }
          !eligible_limits.empty?
        end

        def actionable?(shipment)
          actionable_limit = preferred_product_type_limits.find{|limit| limit[:product_type].eql?(shipment.delivery_mode) }
          return false if actionable_limit.blank?

          products_amount = shipment.line_items.sum{ |line| BigDecimal(line.price_values[:amount]) }
          products_amount >= BigDecimal(actionable_limit[:amount_min].to_s)
        end

        private

        def unique_product_type
          product_types = preferred_product_type_limits.map{ |limit| limit['product_type'] }
          duplicate_product_type = product_types.detect{ |type| product_types.count(type) > 1 }

          if duplicate_product_type.present?
            promotion.errors[:base] << "Promotion rule `Order Limit on Shipment` already contains product type #{duplicate_product_type}"
          end
        end
      end
    end
  end
end
