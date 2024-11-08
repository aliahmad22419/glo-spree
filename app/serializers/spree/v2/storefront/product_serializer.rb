module Spree
  module V2
    module Storefront
      class ProductSerializer < BaseSerializer
        set_type :product

        attributes :name, :brand_name, :preferences, :rrp, :slug, :linked, :sku, :status, :long_description, :description, :featured,
                   :gift_messages, :vendor_sku, :wide_area_delivery, :local_area_delivery, :tax_category_id,
                   :meta_description, :meta_keywords, :meta_title, :restricted_area_delivery, :delivery_days_to_same_country,
                   :delivery_days_to_americas, :delivery_days_to_africa, :delivery_days_to_australia, :delivery_days_to_asia,
                   :delivery_days_to_europe, :delivery_days_to_restricted_area, :sale_price, :manufacturing_lead_time, :stock_status,
                   :delivery_details, :on_sale, :sale_start_date, :sale_end_date, :hide_price, :disable_cart, :pack_size, :minimum_order_quantity,
                   :digital, :product_type, :delivery_mode, :prefix, :suffix, :digital_service_provider, :ts_type, :campaign_code, :effective_date,
                   :hide_from_search, :default_quantity, :disable_quantity, :voucher_email_image, :recipient_details_on_detail_page, :tag, :recipient_email_link,
                   :send_gift_card_via, :enable_product_info, :info_product, :barcode_number, :unit_cost_price, :track_inventory, :daily_stock, :parent_id, :type

        attribute :status do |object|
          (object.status == "active") ? 'approved' : 'pending'
        end

        attribute :hide_prod_price do |object|
          if object.hide_price
            'true'
          else
            'false'
          end
        end

        attribute :parent_attributes do |object|
          (object.try(:parent).present? ? {id: object.parent.id, slug: object.parent.slug} : {})
        end
        
        attribute :batch_in_progress do |object|
          object&.product_batches.pluck(:status).uniq.include?('processing')
        end

        attribute :is_on_sale do |object|
          object.on_sale?
        end

        attribute :banner_image do |object|
          object.active_storge_url(object.banner_image) if object.banner_image.attached?
        end

        attribute :price_values do |object, params|
          object.price_values(params[:default_currency], params[:store])
        end

        # used on admin dashboard, will always return 2 decimals
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

        attribute :intimation_emails do |object|
          object.intimation_emails
        end

        attribute :product_is_gift_card do |object|
          object.product_is_gift_card.to_s
        end

        attribute :category_state do |object|
          JSON.parse(object.category_state) if object.category_state.present?  && object.taxon_ids.present?
        end

        attribute :price do |object, params|
          (object.price_in_currency(params[:default_currency], params[:store]) ||
           object.product_price(params[:default_currency], params[:store]))
        end

        attribute :shipping_category_id do |object|
          object&.shipping_category&.id
        end

        attribute :shipping_category_id do |object|
          object&.shipping_category&.id
        end

        attribute :delivery_options do |object, params|
          if object.delivery_details.present?
            object.delivery_details
          else
            object.delivery_days(params[:store])
          end

        end

        attribute :taxon_category do |object|
          taxon = object.taxons.max {|a,b| a&.permalink&.split('/')&.size <=> b&.permalink&.split('/')&.size }
          { id: taxon.id, name: taxon.name, slug: taxon.slug, permalink: taxon.permalink, ancestors: taxon.ancestors } if taxon.present?
        end

        attribute :purchasable,   &:purchasable?
        attribute :in_stock,      &:in_stock?
        attribute :backorderable, &:backorderable?
        
        attribute :quantity do |object|
          object&.total_on_hand&.to_s.to_i
        end

        attribute :vendor_id do |object|
          object.vendor.id if object.vendor.present?
        end

        attribute :brand_follow_data do |object, params|
          vendor_user = object&.vendor&.users&.first
          data = {vendor_user_id: '', brand_followed: false, follow_request_approved: false}
          if vendor_user.present?
            data['vendor_user_id'] = vendor_user.id
            if params[:followee_user_id].present?
              data['brand_followed'] = true if vendor_user.followed_users.pluck(:followee_id).include?(params[:followee_user_id])
              data['follow_request_approved'] = true if vendor_user.followed_users.approved.pluck(:followee_id).include?(params[:followee_user_id])
            end
          end
          data
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

        attribute :vendor_country do |object|
          object&.vendor&.ship_address&.country&.name
        end

        attribute :vendor_shipping_methods do |object|
          if object&.vendor&.shipping_methods.present?
            true
          else
            false
          end
        end

        attribute :images do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.sort_by{|i|[i.sort_order,i.id]}, options).serializable_hash
        end

        attribute :variant_images do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.sort_by{|i|[i.sort_order,i.id]}, options).serializable_hash
        end

        attribute :base_image do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.where(base_image: true).first, options).serializable_hash
        end

        attribute :small_image do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.where(small_image: true).first, options).serializable_hash
        end

        attribute :thumbnail do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object.variant_images.where(thumbnail: true).first, options).serializable_hash
        end

        attribute :variants do |object, params|
          Spree::V2::Storefront::VariantSerializer.new(object.variants, { params: params }).serializable_hash
        end

        attribute :master_variant do |object|
          object.master.id
        end

        attribute :master_variant_sku do |object|
          object.master.sku
        end

        attribute :option_types do |object|
          object.option_type_ids.map{|id| id.to_s}
        end

        attribute :option_types_names do |object|
          object.option_types.map(&:presentation)
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

        attribute :store_ids do |object, params|
          store_ids = object.store_ids.map{|id| id.to_s}
          ids = params[:allow_store_ids].present? ? (store_ids & params[:allow_store_ids]) : store_ids
          ids
        end

        attribute :taxon_ids do |object|
          object.taxon_ids.map{|id| id.to_s}
        end

        attribute :without_vendor_taxon do |object|
          object.taxons.where("vendor_id IS NULL").map{|t| t.id.to_s}
        end

        attribute :system_taxon_ids do |object|
          Spree::Taxon.ids.map{|id| id.to_s}
        end

        attribute :taxon_slugs do |object|
          object.taxons.map(&:slug)
        end

        attribute :taxon_names do |object|
          object.taxons.where("vendor_id IS NULL")&.map(&:name)&.uniq&.join(", ")
        end

        attribute :reviews do |object|
          object.reviews
        end

        attribute :product_properties do |object|
          object.product_properties
        end

        attribute :product_type_properties do |object|
          type_property_id = object&.properties&.where(name: "Product Type")&.last&.id
          type_properties = ""
          if type_property_id
            type_properties = object&.product_properties&.where(property_id: type_property_id)&.map(&:value)&.join('+')
          end
          type_properties
        end

        attribute :properties_with_values do |object|
          properties_with_values = []
          object.properties.uniq.each do |pro|
            values = object.product_properties.where(property_id: pro.id).select("value").map{|v| (pro.presentation.to_s + "-" + v.value).parameterize}
            properties_with_values.push values
          end
          properties_with_values.flatten
        end

        attribute :blocked_dates do |object|
          object.blocked_dates.map{ |range| eval(range) }
        end

        attribute :store_names do |object, params|
          if params && params[:user] && params[:user].has_spree_role?('sub_client')
            object.stores.where(id: params[:user][:allow_store_ids]).map{|store| store.name}
          else
            object.stores.map {|store| store.name}
          end
        end

        attribute :tag do |object|
          object.tag_list.first
        end

        attribute :linked_vendor_group do |object|
          res = []
          object.client.vendors.each do |vendor|
            res << vendor.id if vendor.vendor_group.present?
          end
          res
        end

        attribute :stock_dates do |object|
          object.stock_products&.effective&.pluck(:effective_date) if object.daily_stock?
        end

        attribute :stock_type do |object|
          stock_status = []
          stock_status.push 'Disabled Stock' unless object.track_inventory
          stock_status.push 'Linked' if object.linked?
          stock_status.push 'DailyStock' if object.daily_stock?
          stock_status.join(',').presence
        end

        attribute :timezone_list do |object|
          object.timezone_list if object.daily_stock?
        end

        attribute :out_of_stock do |object|
          if object.daily_stock # For daily stock it depends on child product
            false
          else
            (!object.stock_status || (object.track_inventory && object.count_on_hand == 0))
          end
        end
      end
    end
  end
end
