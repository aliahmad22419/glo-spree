module Spree
    module V2
      module Storefront
        class IframeProductSerializer < BaseSerializer
          set_type :product
  
          attributes :name, :brand_name, :vendor_sku 

          attribute :variants do |object|
            Spree::V2::Storefront::VariantSerializer.new(object.variants).serializable_hash
          end

          attribute :custom_options do |object|
            object.customizations.first.customization_options.where.not(label: "Customize (add additional amount to card)").order("id asc")
          end
  
          attribute :iframe_flow_store do |object|
             object.stores.first
          end
          
          attribute :variant_images do |object, params|
            options = {
                params: params
            }
            Spree::V2::Storefront::ImageSerializer.new(object.variant_images.sort_by{|i|[i.sort_order,i.id]}, options).serializable_hash
          end

          attribute :customizations do |object, params|
            options = {
                params: {exchange_rate: object.exchange_rate(params[:default_currency])}
            }
            if params[:store_id].present?
              Spree::V2::Storefront::CustomizationSerializer.new(object.customizations.where("'#{params[:store_id]}' = ANY(store_ids)").order(:order),options).serializable_hash
            else
              Spree::V2::Storefront::CustomizationSerializer.new(object.customizations.order(:order),options).serializable_hash
            end
          end

          attribute :store_currency do |object|
            object.stores.first.default_currency
         end
         
          attribute :currencies do |object|
              ::Money::Currency.table.uniq {|c| c[1][:iso_code]}.map do |_code, details|
                iso = details[:iso_code]
                [iso, "#{details[:name]} (#{iso})"]
              end
          end

        end
      end
    end
  end
  