module Spree
  module V2
    module Storefront
      class VariantSerializer < BaseSerializer
        set_type :variant

        attributes :sku, :price, :options_text, :images, :barcode_number, :track_inventory, :is_master, :weight

        attribute :custom_options_text do |object|
          object.options_text.gsub(", and ",", ")
        end

        attribute :option_values do |object|
          option_values_array = []
          object.option_values.map{|ov|
            option_values_array.push ({id: ov.id, name: ov.name,position: ov.position, option_type_id:  ov.option_type_id, presentation: ov.presentation, option_type_name: ov.option_type.presentation})
          }
          option_values_array
        end

        attribute :rrp do |object, params|
          object.product.tp(object.rrp.to_f, params[:default_currency])
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

        # used on admin dashboard, will always return 2 decimals
        attribute :non_exchanged_price_values do |object, params|
          { price: "%.2f" % (object.price || 0), rrp: "%.2f" % (object.rrp || 0), unit_cost_price: "%.2f" % (object.unit_cost_price || 0)  }
        end

        attribute :quantity do |object|
          object.total_on_hand.to_s.to_i
        end

        attribute :wished_products do |object|
          object.wished_items
        end
        
        attribute :images do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.images.sort_by{|i|[i.sort_order,i.id]}.reverse, options).serializable_hash
        end

        attribute :archived do |object|
          object.archived.to_s
        end

        attribute :out_of_stock do |object|
          (!object.product.stock_status || (object.track_inventory && object.total_on_hand.to_s.to_i == 0))
        end

      end
    end
  end
end
