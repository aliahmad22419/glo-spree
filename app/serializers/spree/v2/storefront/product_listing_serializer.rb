module Spree
  module V2
    module Storefront
      class ProductListingSerializer < BaseSerializer
        set_type :product

        attributes :name, :brand_name, :rrp, :slug, :sku, :option_types, :prefix, :suffix

        attribute :price do |object, params|
          (object.price_in_currency(params[:default_currency], params[:store]) ||
           object.product_price(params[:default_currency], params[:store]))
        end

        attribute :price_values do |object, params|
          object.price_values(params[:default_currency], params[:store])
        end

        attribute :variants_options do |object, params|
          store = params[:store]
          swatches = {"color": [], "size": []}
          if store.is_show_swatches == true
            swatches["color"] = object.color_swatches.uniq  if store.swatches.include?('color')
            swatches["size"] = object.size_swatches.uniq  if store.swatches.include?('size')
          end
          swatches
        end


        attribute :tax do |object, params|
          object.calculated_tax(params[:default_currency], params[:store].try(:id))
        end

        attribute :hide_prod_price do |object, params|
          object.hide_price ? 'true' : 'false'
        end

        attribute :vendor_name do |object|
          object.vendor.name if object.vendor.present?
        end

        attribute :vendor_landing_page do |object|
          object.vendor.landing_page_url if object.vendor.present?
        end

        attribute :vendor_slug do |object|
          object.vendor.slug if object.vendor.present?
        end

        attribute :vendor_microsite do |object|
          object.vendor.microsite.to_s if object.vendor.present?
        end

        attribute :images do |object, params|
          options = {
            params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.order(:sort_order, :id), options).serializable_hash
        end

        attribute :small_image do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.where(small_image: true).first, options).serializable_hash
        end

        attribute :tag do |object|
          object.tag_list.first
        end
        
      end
    end
  end
end
