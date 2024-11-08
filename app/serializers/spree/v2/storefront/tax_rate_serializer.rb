module Spree
  module V2
    module Storefront
      class TaxRateSerializer < BaseSerializer
        set_type :tax_rate

        attributes :name, :amount, :show_rate_in_label, :included_in_price

        attribute :calculator do |object|
          object.calculator.description
        end
        
        attribute :preferences do |object|
          object.calculator.preferences
        end

        attribute :calculator_type do |object|
          object.calculator.type
        end

        attribute :zone_id do |object|
          object.zone_id.to_s
        end

        attribute :tax_category_id do |object|
          object.tax_category_id.to_s
        end
        
      end
    end
  end
end
