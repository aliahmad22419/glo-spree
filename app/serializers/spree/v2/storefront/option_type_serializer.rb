module Spree
  module V2
    module Storefront
      class OptionTypeSerializer < BaseSerializer
        set_type :option_type

        attributes :name, :presentation

        attribute :option_values do |object|
          object.option_values.map{|ov| {id: ov.id, name: ov.name, presentation: ov.presentation, variants: (ov.variants.where("product_id IS NOT NULL").count > 0? "true" : "false")}}
        end
      end
    end
  end
end
