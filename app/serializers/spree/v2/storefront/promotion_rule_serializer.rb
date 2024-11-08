module Spree
  module V2
    module Storefront
      class PromotionRuleSerializer < BaseSerializer
        set_type :promotion_rule

        attributes :id, :promotion_id, :user_id, :type, :code, :preferences

        attribute :product_ids do |object|
          object&.product_ids if object.type == "Spree::Promotion::Rules::Product"
        end

        attribute :user_ids do |object|
          object&.user_ids if object.type == "Spree::Promotion::Rules::User"
        end

        attribute :taxon_ids do |object|
          object&.taxon_ids if object.type == "Spree::Promotion::Rules::Taxon"
        end
        
      end
    end
  end
end
