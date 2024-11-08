module Spree
  module V2
    module Storefront
      class VariantRefundSerializer < BaseSerializer
        attributes :id

        attribute :option_values do |object|
          object.option_values
        end

        attribute :product do |object|
          Spree::V2::Storefront::ProductSerializer.new(object.product).serializable_hash
        end

        attribute :price_values do |object, params|
          product = object.product
          ex = product.exchange_rate(params[:default_currency])

          if product.on_sale?
            prices = product.price_values(params[:default_currency], params[:store])
            { price: prices[:final_price], rrp: prices[:rrp] }
          else
            {
              price: product.tp(object.price_with_delivery_charges(params[:store]) * ex, params[:default_currency]),
              rrp: product.tp(object.rrp.to_f, params[:default_currency])
            }
          end
        end
      end
    end
  end
end
