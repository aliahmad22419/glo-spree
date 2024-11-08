module Spree
  module V2
    module Storefront
      class CustomizationSerializer < BaseSerializer
        set_type :customization

        attributes :show_price, :label, :field_type, :price, :is_required, :order, :store_ids, :max_characters
        
        attribute :customization_options do |object, params|
          object.customization_options.select("label,value,sku,id,max_characters, color_code,price * #{params[:exchange_rate]} as price, price as non_exchanged_price")
        end
        
      end
    end
  end
end


