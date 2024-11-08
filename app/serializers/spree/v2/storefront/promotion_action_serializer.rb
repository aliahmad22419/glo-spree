module Spree
  module V2
    module Storefront
      class PromotionActionSerializer < BaseSerializer
        set_type :promotion_action

        attributes :id, :promotion_id, :type, :exclude_sale_items

        attribute :calculator do |object|
          object.calculator.description if ["CreateLineItems", "FreeShipping", "BinCodeDiscount"].exclude?(object.type.demodulize)
        end

        attribute :action_preferences do |object|
          object.preferences
        end

        attribute :preferences do |object|
          object.calculator.preferences if ["CreateLineItems", "FreeShipping", "BinCodeDiscount"].exclude?(object.type.demodulize)
        end

        attribute :calculator_type do |object|
          object.calculator.type if ["CreateLineItems", "FreeShipping", "BinCodeDiscount"].exclude?(object.type.demodulize)
        end

        attribute :line_item do |object|
          object&.promotion_action_line_items&.first if object.type == "Spree::Promotion::Actions::CreateLineItems"
        end

      end
    end
  end
end
