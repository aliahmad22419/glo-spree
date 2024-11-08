module Spree
  module V2
    module Storefront
      class WishlistSerializer < BaseSerializer
        set_type :wishlist

        attributes :name, :token, :is_private, :is_default

        attribute :wished_products do |object, params|
          wished_products = object.wished_items.joins(variant: :product).where('spree_products.hide_from_search = ?', false)
          Spree::V2::Storefront::WishedItemSerializer.new(wished_products, params: params).serializable_hash
        end

      end
    end
  end
end
