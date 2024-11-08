module Spree
  module V2
    module Storefront
        class WishedItemSerializer < BaseSerializer

          set_type :wished_product

          attributes :quantity

          attribute :display_total do |wished_item, params|
            wished_item.display_total(currency: params[:currency]).to_s
          end
  
          attribute :prodcut_id do |object, params|
            object.variant.product.id
          end
  
          attribute :prodcut do |object, params|
            Spree::V2::Storefront::ProductSerializer.new(object.variant.product, params: params).serializable_hash
          end
        end
    end
  end
end
