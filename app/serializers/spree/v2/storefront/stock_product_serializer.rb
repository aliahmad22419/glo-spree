module Spree
  module V2
    module Storefront
      class StockProductSerializer < BaseSerializer
        set_type :stock_product

        attributes :name, :slug, :linked, :sku, :status, :vendor_sku, :sale_price, :stock_status, :default_quantity, :pack_size,
                   :disable_quantity, :info_product, :barcode_number, :unit_cost_price, :daily_stock, :effective_date, :minimum_order_quantity, :preferences, :id

        attribute :price do |object, params|
          (object.price_in_currency(params[:default_currency], params[:store]) ||
           object.product_price(params[:default_currency], params[:store]))
        end

        attribute :non_exchanged_price_values do |object|
          prices_hash = {
            price: object.price,
            sale_price: object.sale_price,
            local_area_delivery_price: object.local_area_delivery,
            wide_area_delivery_price: object.wide_area_delivery,
            rrp: object.rrp,
            unit_cost_price: "%.2f" % (object.unit_cost_price || 0)
          }

          prices_hash.each { |key, value| prices_hash[key] = "%.2f" % (value || 0) }
        end
        
        attribute :variants do |object, params|
          VariantSerializer.new(object.variants_including_master.unarchived, { params: params }).serializable_hash
        end

        attribute :parent_attributes do |object|
          object.parent.attributes.slice('id', 'slug')
        end

        attribute :stock_type do |object|
          'Linked' if object.linked?
        end

        attribute :in_stock, &:in_stock?
        attribute :quantity, &:total_on_hand
      end
    end
  end
end
