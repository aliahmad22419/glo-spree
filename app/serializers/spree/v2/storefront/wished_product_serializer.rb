module Spree
  module V2
    module Storefront
      class WishedProductSerializer < BaseSerializer
        set_type :wished_product

        attributes :quantity, :display_total

        attribute :prodcut_id do |object|
          object.variant.product.id
        end

        attribute :prodcut do |object, params|
          Spree::V2::Storefront::ProductSerializer.new(object.variant.product, params: params).serializable_hash
        end

      end
    end
  end
end
