module Spree
  module V2
    module Storefront
      class LineItemCustomizationSerializer < BaseSerializer
        set_type :line_item_customization
        belongs_to :line_item
        attributes :id, :name, :title, :value, :customization_option_id, :line_item_id,
                   :field_type, :customization_id

        attribute :price do |object, params|
          object.line_item.tp(object.price * object.line_item.apply_exchange_rate(params[:default_currency]), params[:default_currency])
        end

        attribute :image do |object|
          Spree::V2::Storefront::ImageSerializer.new(object.image).serializable_hash
        end
      end
    end
  end
end
