module Spree
  module Api
    module V2
      module Storefront
        class ProductsController < ::Spree::Api::V2::BaseController
          require 'csv'
          before_action :require_spree_current_user, :if => Proc.new{ params[:access_token] }
          before_action :check_permissions
          before_action :set_products, only: [:remove_from_category, :add_to_category, :reinstate]
          before_action :set_admin_products, only: [:trashbin, :change_status, :approved, :destroy_multiple]
          before_action :set_product, only: [:update, :update_iframe_product, :destroy]
          before_action :destory_already_present_properties, only: [:update]
          before_action :authorized_client_sub_client_vendor, only: [:create,:update,:destroy,:destroy_multiple,:update_stock, :import_stocks]

          def index
            params[:q] = params[:q].present? && valid_json?(params[:q]) ? JSON.parse(params[:q]).merge!({"type_null": true}) : {"type_null": true}
            if @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"vendor")
              q = @spree_current_user.vendors.first.products.untrashed.ransack(params[:q])
              products = q.result
              products = collection_paginator.new(products, params).call unless params[:q].present? && params[:q][:stock_import].present?
              render_serialized_payload { serialize_vendor_products_collection(products) }

            elsif @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"admin")
              q = Spree::Product.ransack(params[:q])
              products = q.result
              products = collection_paginator.new(products, params).call
              render_serialized_payload { serialize_vendor_products_collection(products) }
            elsif @spree_current_user.present? && (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              params[:q][:stores_id_in] =  @spree_current_user.allow_store_ids if @spree_current_user.user_with_role("sub_client")
              q = params[:q].present? && params[:q][:stock_import].present? ? current_client.master_vendor.products.ransack(params[:q]) : current_client.products.accessible_by(current_ability).ransack(params[:q])
              products = q.result
              products = sorted_collection(products).uniq
              products = collection_paginator.new(products, params).call unless params[:q].present? && params[:q][:stock_import].present?
              render_serialized_payload { serialize_vendor_products_collection(products) }
            else
              params.merge!(store: spree_current_store)
              if params[:q].present? && params[:q][:price_between_with_currency].present?
                price_filter_values = params[:q][:price_between_with_currency]
                params[:q].delete("price_between_with_currency")
              end
              active_vendor_ids = storefront_current_client.vendors.active.select("id").pluck(:id)
              q = spree_current_store.products.untrashed.approved.in_stock_status.product_quantity_count.not_hide_from_search.where(vendor_id: active_vendor_ids).ransack(params[:q])
              products = q.result

              get_featured = (params[:q][:get_featured] rescue false)
              products = sorted_collection(products).uniq unless get_featured
              if get_featured
                featured = products.where(featured: true).uniq
                more_featured = 5 - featured.count
                if more_featured > 0
                  nonfeatured = products.where("spree_products.featured IS NULL OR spree_products.featured = ?",false)
                  nonfeatured = nonfeatured.uniq.sample(more_featured)
                  featured = featured + nonfeatured
                end
                products = featured
                products = products.sort_by(&:created_at).reverse
              end
              products = Spree::Product.price_between_with_currency(price_filter_values, products, spree_current_store) if price_filter_values.present?
              products = collection_paginator.new(products, params).call
              render_serialized_payload { serialize_collection(products) }
            end
          end

          def destroy
            if @product.destroy
              render_serialized_payload { serialize_resource(@product) }
            else
              render_error_payload(failure(@product).error)
            end
          rescue Exception => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def curation_products
            params[:q] = params[:q].present? && valid_json?(params[:q]) ? JSON.parse(params[:q]).merge!({"type_null": true}) : {"type_null": true}
            if params[:q].present?
              taxon_id = params[:q].delete("taxons_id_eq")
              store_id = params[:q].delete("stores_id_eq")
              store = Spree::Store.find_by('spree_stores.id = ?', store_id)
            end
            products = []
            if taxon_id.present? && store_id.present?
              q = Spree::Product.untrashed.approved.in_stock_status.product_quantity_count.joins("INNER JOIN spree_products_taxons ON spree_products_taxons.product_id = spree_products.id")
              q = q.where('spree_products_taxons.store_id = ? AND spree_products_taxons.taxon_id = ?', store_id, taxon_id)
              q = q.select("spree_products.*, spree_products_taxons.position")
            else
              q = store.products.untrashed.approved.in_stock_status.product_quantity_count
              q = q.select("spree_products.*")
            end

            if params["sort"].present?
              sort_order = (String(params["sort"])[0] == '-' ? "DESC" : "ASC")
              sort_field = (String(params["sort"])[0] == '-' ? params["sort"][1..-1] : params["sort"])
              q = q.order("spree_products.created_at #{sort_order}") if sort_field.eql?("created_at")
              q = q.order("spree_products.updated_at #{sort_order}") if sort_field.eql?("updated_at")
              if sort_field == "best_seller" || sort_field == "manually"
                q = q.order("spree_products_taxons.position ASC")
              end
            end

            q = q.ransack(params[:q])
            # products = q.result.limit(params[:per_page].to_i).offset((params[:page].to_i - 1) * params[:per_page].to_i)
            products = q.result

            products = collection_paginator.new((products).uniq, params).call

            render_serialized_payload { serialize_vendor_products_collection(products) }
          end

          def category_products_nonelastic
            params[:q] = params[:q].present? && valid_json?(params[:q]) ? JSON.parse(params[:q]).merge!({"type_null": true}) : {"type_null": true}
            store_id = spree_current_store.id
            if params[:q].present?
              taxon_permalink = params[:q].delete("taxons_permalink_eq")
              price_filter_values = params[:q].delete("price_between_with_currency")
              search_term = params[:q].delete("name_or_brand_name_or_vendor_name_or_vendor_sku_or_meta_keywords_cont")
              search_term.upcase! if search_term.present?
              vendor_slug = params[:q].delete("vendor_slug_eq")
              params[:q].delete("stores_id_eq")
            end

            products = []
            taxon_id = storefront_current_client.taxons.where(permalink: taxon_permalink).select("id").pluck(:id)
            active_vendor_ids = storefront_current_client.vendors.active.select("id").pluck(:id)
            # local_country_id = 536
            # restricted_countries_ids = [500, 546,  599]
            # currency = 'SGD'
            q = Spree::Product.untrashed.approved.in_stock_status.product_quantity_count
                # .joins("INNER JOIN spree_products_taxons ON spree_products_taxons.product_id = spree_products.id")
            taxons_products_query = "SELECT product_id, MIN(position) AS position
                                     FROM spree_products_taxons
                                     WHERE store_id = #{store_id}
                                     GROUP BY product_id"

            q = if search_term.present?
              q.joins("INNER JOIN spree_vendors ON spree_products.vendor_id = spree_vendors.id")
                .joins("INNER JOIN (#{taxons_products_query}) AS taxon_products ON spree_products.id = taxon_products.product_id")
                .where("spree_products.vendor_id IN (?)", active_vendor_ids)
                .where("(((upper(spree_products.name) LIKE ? OR upper(spree_vendors.name) LIKE ?) OR upper(spree_vendors.sku) LIKE ?) OR upper(spree_products.meta_keywords) LIKE ?)", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
            elsif vendor_slug.present?
              q.joins("INNER JOIN spree_vendors ON spree_products.vendor_id = spree_vendors.id")
               .joins("INNER JOIN (#{taxons_products_query}) AS taxon_products ON spree_products.id = taxon_products.product_id")
               .where("spree_vendors.slug = ?", vendor_slug)
            elsif taxon_id.present?
              taxons_products_query = "SELECT * FROM spree_products_taxons WHERE store_id = #{store_id}"
              q.joins("INNER JOIN (#{taxons_products_query}) AS taxon_products ON spree_products.id = taxon_products.product_id")
               .where("spree_products.vendor_id IN (?) AND taxon_products.taxon_id = ?", active_vendor_ids, taxon_id)
            end

            sort_field = "nil"
            if params["sort"].present?
              sort_field = (String(params["sort"])[0] == '-' ? params["sort"][1..-1] : params["sort"])
            end

            if price_filter_values.present? || sort_field.eql?("price")
              low, high, currency = price_filter_values
              currency = params["currency"] if currency.blank?
              restricted_ids = Spree::Country.where(name: RESTRICTED_AREAS).ids.join(',')
              price_column = if spree_current_store&.country_specific
                "CASE
                  WHEN spree_product_currency_prices.vendor_country_id = #{spree_current_store.country_ids[0]} THEN spree_product_currency_prices.local_area_price
                  WHEN spree_product_currency_prices.vendor_country_id IN (#{restricted_ids}) THEN spree_product_currency_prices.restricted_area_price
                  ELSE spree_product_currency_prices.wide_area_price
                 END calculated_price"
               else
                 "price as calculated_price"
               end

               price_query = "SELECT vendor_id, product_id, #{price_column}
                              FROM public.spree_product_currency_prices
                              WHERE to_currency = '#{currency}'
                              AND vendor_id IN (#{active_vendor_ids.join(',')})"

               q = q.joins("INNER JOIN(#{price_query}) prices ON spree_products.id = prices.product_id")
               q = q.where("calculated_price BETWEEN #{low} AND #{high}") if price_filter_values.present?
            end

            positioned_q = q.select("spree_products.*, taxon_products.position")
            q = q.select("spree_products.*")

            if params["sort"].present?
              sort_order = (String(params["sort"])[0] == '-' ? "DESC" : "ASC")
              sort_field = (String(params["sort"])[0] == '-' ? params["sort"][1..-1] : params["sort"])
              q = q.order("spree_products.name #{sort_order}") if sort_field.eql?("name")
              q = q.order("spree_products.created_at #{sort_order}") if sort_field.eql?("created_at")
              q = q.order("spree_products.updated_at #{sort_order}") if sort_field.eql?("updated_at")
              q = q.order("calculated_price #{sort_order}") if sort_field.eql?("price")
              classified_products = if sort_field.eql?("best_seller") || sort_field.eql?("manually")
                positioned_q = positioned_q.order("taxon_products.position ASC")
                positioned_q.ransack(params[:q]).result
              else
                nil
              end
            end

            page_number = (params["page"] || 1).to_i
            per_page = (params["per_page"] || 24).to_i
            offset = (page_number - 1) * per_page
            if classified_products.present?
              positioned_q = positioned_q.limit(per_page).offset(offset)
              products = positioned_q.ransack(params[:q]).result
            else
              classified_products = q.ransack(params[:q]).result
              q = q.limit(per_page).offset(offset)
              q = q.ransack(params[:q])
              products = q.result
            end
            render_serialized_payload { serialize_collection(products, classified_products) }
          end

          def category_products
            params[:q] = params[:q].present? && valid_json?(params[:q]) ? JSON.parse(params[:q]).merge!({"type_null": true}) : {"type_null": true}
            options = { store_id: spree_current_store.id }
            if params[:q].present?
              options[:property_filters] = params[:q][:property_filters][0].to_unsafe_h if params[:q][:property_filters].present?
              options[:taxon_permalink] = params[:q].delete("taxons_permalink_eq")
              options[:price_filter_values] = params[:q].delete("price_between_with_currency")

              decoded_term = params[:q].delete("name_or_brand_name_or_vendor_name_or_vendor_sku_or_meta_keywords_cont")
              decoded_term ||= ""
              begin
                decoded_term = URI.decode(decoded_term)
              end while(decoded_term != URI.decode(decoded_term))

              options[:search_term] = decoded_term

              if params[:q][:vendor_slug_eq].present? && storefront_current_client.vendors.active.where(slug: params[:q][:vendor_slug_eq])&.first
                options[:vendor_slug] = params[:q].delete("vendor_slug_eq")
              end

              params[:q].delete("stores_id_eq")
            end
            options[:taxon_id] = storefront_current_client.taxons.where(permalink: options[:taxon_permalink]).select("id").pluck(:id)
            options[:active_vendor_ids] = storefront_current_client.vendors.active.select("id").pluck(:id)
            options[:sort] = params["sort"]
            options[:restricted_ids] = Spree::Country.where(name: RESTRICTED_AREAS).ids
            options[:default_currency] = params["currency"]

            classified_products, products = Spree::Product.searche(spree_current_store, options, params, true)
            render_serialized_payload { serialize_listing(products, classified_products) }
          end

          def related_products
            per_page = (params[:per_page] || 4)
            store_products = spree_current_store.products.active_vendor_products.untrashed.approved.not_hide_from_search
            @product = Spree::Product.friendly.find(params[:id])

            related_products = store_products.where(id: 0) # @product.relations.order("RANDOM()").limit(per_page).map{ |obj| obj.related_to }
            vendor_products = store_products.where(vendor_id: @product&.vendor_id).where.not(id: @product.id).order("RANDOM()").limit(per_page)
            render_serialized_payload { related_product_collection(related_products, vendor_products) }
          end

          def viewed_recently
            recent_ids = params[:product] && params[:product][:ids]
            recent_ids = spree_current_user.recent_product_ids if spree_current_user.present?

            products = spree_current_store.products.active_vendor_products.untrashed.approved.not_hide_from_search
            products = products.recently_viewed(recent_ids)
            render_serialized_payload { serialize_vendor_products_collection(products) }
          end

          def add_to_category
            @products.each do |p|
              next if p.taxon_ids.include? params[:category_id].to_i
              p.selected_taxon_ids  = p.taxon_ids << params[:category_id].to_i
              p.save
            end
            render_serialized_payload { success({success: true}).value }
          end

          def remove_from_category
            @products.each do |p|
              if p.taxon_ids.include? params[:category_id].to_i
                taxons = p.taxon_ids
                taxons.delete(params[:category_id].to_i)
                p.taxon_ids = taxons
                p.save
              end
            end
            render_serialized_payload { success({success: true}).value }
          end

          def recent
            if spree_current_user.blank?
              render json: { message: "You are not authorized to perform this action" }, status: 401
            elsif params[:product] && params[:product][:ids]
              spree_current_user.recent_product_ids = params[:product][:ids]
              render json: { saved: spree_current_user.save }, status: 200
            else
              render json: { message: "invalid request" }, status: 400
            end
          end

          def option_types
            vendor_id = current_client.present? ? current_client&.vendors&.first&.id : @spree_current_user&.vendors&.first&.id
            vendor_option_types = current_client.present? ? current_client.option_types.includes(:option_values).where(vendor_id: vendor_id).uniq : Spree::OptionType.includes(:option_values).where(vendor_id: vendor_id).uniq
            admin_option_types = current_client.present? ? current_client.option_types.includes(:option_values).where("vendor_id IS NULL").uniq : Spree::OptionType.includes(:option_values).where("vendor_id IS NULL").uniq
            option_types = vendor_option_types + admin_option_types
            render_serialized_payload { serialize_option_type_collection(option_types) }
          end

          def personlizations
            personlizations = Spree::Personalization.all
            render_serialized_payload { serialize_personlization_collection(personlizations) }
          end

          def stores
            if @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"vendor")
              vendor = @spree_current_user.vendors.first
              client_zone_based_stores = vendor&.client&.zone_based_stores
              if client_zone_based_stores
                shipping_method_zones = vendor.shipping_methods.map{|sm| sm.zone_ids}.flatten
                stores = []
                current_client.stores.each do |store|
                  include_all = store.zone_ids.all? { |e| shipping_method_zones.include?(e) }
                  next if include_all == false
                  stores.push(store)
                end
              else
                stores = current_client.present? ? current_client.stores : Spree::Store.all
              end

            else
              if @spree_current_user.user_with_role("client")
                stores = current_client.stores
              else
                stores = current_client.stores.where(id: @spree_current_user.allow_store_ids)
              end
            end

            render_serialized_payload { serialize_store_collection(stores) }
          end

          def get_properties
            # properties = current_client.present? ? current_client.properties.where(name: ['Type','Feature']).first(2) : Spree::Property.where(name: ['Type','Feature']).first(2)
            properties = current_client.properties
            render_serialized_payload { serialize_properties_collection(properties) }
          end

          def shipping_categories
            shipping_categories = current_client.present? ? current_client.shipping_categories : Spree::ShippingCategory.all
            taxons = current_client.present? ? current_client.taxons.ids.map{|id| id.to_s} : Spree::Taxon.ids.map{|id| id.to_s}
            data = {shipping_categories: shipping_categories, taxons: taxons}
            render json: data.to_json
          end

          def image
            pro = Spree::Product.find_by(slug: params[:slug])
            image = pro.images.where(base_image: true).first.present? ? pro.images.where(base_image: true).first : pro.images.first
            url = image.present? ? "https://glo.techsembly.com" + image.styles.last[:url] : ""
            render json: url.to_json
          end

          def taxons
            taxons = current_client.present? ? current_client.taxons.not_vendor.select("id,name,slug").where('parent_id IS NULL').where(hide_from_vendors: false).order('id ASC') : Spree::Taxon.select("id,name,slug").where('parent_id IS NULL').order('id ASC')
            render json: taxons.to_json(:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children =>{:include =>{:children => {:include => {:children => {:only => [:id, :name, :slug] }},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug]}},:only => [:id, :name, :slug] }},:only => [:id, :name, :slug] }})
          end

          def create
            vendor = params[:vendor_id].present? ? Spree::Vendor.find_by('spree_vendors.id = ?', params[:vendor_id]) : (@spree_current_user.vendors.first || current_client&.master_vendor)
            taxon_ids = params[:taxon_ids] << vendor&.taxon&.id&.to_s
            taxon_ids = taxon_ids.uniq.to_a
            Product.transaction do
              product_params_hash = {price: params[:price], vendor_sku: params[:sku], option_type_ids: params[:option_type_ids], store_ids: params[:store_ids], selected_taxon_ids: taxon_ids, available_on: DateTime.now, category_state: params[:category_state], client_id: current_client&.id, delivery_details: params[:delivery_details], hide_price: params[:hide_price], disable_cart: params[:disable_cart]}
              product = vendor.products.new(product_params.merge(product_params_hash))
              product.update_preferences(params[:preferences]) if params[:preferences].present?
              if product.save!
                product.set_master_variant_weight if params[:preferences].present? && params[:preferences][:is_weighted]
                update_stock_items(product)
                create_variants(params[:variants], product) if params[:variants].present?
                product.update_images(params[:images_ids], params[:deleted_images_ids]) if params[:images_ids].present?
                product&.stores&.last.create_routing("/#{product&.slug}") if spree_current_user&.state.eql?("createproduct") && !product&.client&.multi_vendor_store && product&.stores&.last.fast_track?
                render_serialized_payload { success({success: true}).value  }
              else
                render_error_payload(failure(product).error)
              end
            end
          end

          def update
            vendor = @product.vendor
            vendor_taxon_id = vendor&.taxon&.id
            taxon_ids = params[:taxon_ids]
            taxon_ids << vendor_taxon_id if !params[:taxon_ids].include?vendor_taxon_id.to_s
            product_params_hash = {vendor_sku: params[:sku], option_type_ids: params[:option_type_ids], store_ids: params[:store_ids], selected_taxon_ids: taxon_ids, price: params[:price], category_state: params[:category_state], delivery_details: params[:delivery_details], hide_price: params[:hide_price], disable_cart: params[:disable_cart]}

            if @product.update(product_params.merge(product_params_hash))
              @product.update_preferences(params[:preferences]) if params[:preferences].present?
              @product.set_master_variant_weight if params[:preferences].present? && params[:preferences][:is_weighted]
              @product.update_images(params[:images_ids], params[:deleted_images_ids]) if params[:images_ids].present? || params[:deleted_images_ids].present?
              if params[:variants].present?
                update_stock_items(@product) if params[:variants].all? {|variant| variant["archived"] == "true"} && !@product.linked
                update_variants(params[:variants], @product)
              else
                update_stock_items(@product) unless @product.linked
                @product.variants.delete_all
              end
              # render_serialized_payload { serialize_resource(@product) }
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@product).error)
            end
          rescue Exception => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def update_iframe_product
            begin
              ActiveRecord::Base.transaction do
                store = @product.stores.first
                @product.update(product_params)
                store.update_iframe_store(params, @product.slug)
                @product.iframe_store_v3_flow_address(store) if current_client.client_address.present? 
                current_client.update(supported_currencies: [params[:store_currency]])
                front_desk_user = current_client.users.joins(:spree_roles).where("spree_roles.name = ?", 'front_desk').last
                front_desk_user&.front_desk_credential&.update_columns(tsdefault_currency: store.default_currency) if front_desk_user.present?
                @product.update_images(params[:images_ids], params[:deleted_images_ids]) if params[:images_ids].present? || params[:deleted_images_ids].present?
              end
              render json: { message: "product updated successfully" }, status: 200
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end
          end
          def upload_image
             if params[:file].present?
              img = Spree::Image.new(viewable_type: "Spree::Variant", attachment_file_name: params[:file].original_filename, sort_order: params[:sort_order], viewable_id: params[:viewable_id])  
              img.attachment.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
              if img.save!
                serilizaed_image = Spree::V2::Storefront::ImageSerializer.new(img).serializable_hash
                render_serialized_payload { serilizaed_image }
              else
                render_error_payload(failure(img).error)
              end
            end
          end

          def upload_gallery_image
            images = Spree::Image.where(id: JSON.parse(params[:image_ids]))
            serialized_images = []

            begin
              images.each do |image|
                img = image.duplicate_without_viewable
                serialized_images.push(img)
              end
              render_serialized_payload { serialize_image_collection(serialized_images) }
            rescue Exception => e
              return render_error_payload(e.message, 422)
            end
          end

          def update_stock
            qty = params[:qty].to_i
            main_object = if params[:type] == "variant"
              Spree::Variant.find_by('spree_variants.id = ?', params[:id])
            else
              Spree::Product.find_by('spree_products.id = ?', params[:id])
            end
            return render json: {error: "You are not authoirzed to access this resource"},status: 403 unless can_manage_update_stock?(main_object.class.name == "Spree::Variant" ? main_object.product : main_object)
            stock_obj = main_object.stock_items.first
            stock_obj.count_on_hand = qty
            if stock_obj.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@product).error)
            end
          end

          def import_stocks
            csv_text = File.read(params[:file].path)
            csv = CSV.parse(csv_text, :headers => true)
            csv.each do |row|
              render json: { error: "Forbidden Entity" }, status: :unprocessable_entity and return if forbidden_tag_exist? row.to_s
              if (row["Variant Id"].present?)
                instance = Spree::Variant.find_by('spree_variants.id = ?', row['Variant Id'])
                if instance.present? && !instance.product.linked
                  new_qty = row["Stock Quantity"].to_i
                  next unless can_manage_import_stock?(instance)
                  instance.stock_items.first.update_attribute("count_on_hand", new_qty)
                end
              end
            end
            render_serialized_payload { success({success: true}).value  }
          end

          def show
            if spree_current_store.present?
              spree_product = Rails.cache.fetch("#{params[:id]}-store-#{spree_current_store&.id}") do
                product = resource
                render_error_payload(I18n.t("spree.not_found"), 404) and return unless product&.vendor&.agreed_to_client_terms?
                serialize_resource(product)
              end
              render_serialized_payload{spree_product}
            else
              render_serialized_payload { serialize_resource(resource) }
            end
          end

          def iframe_flow_product
            product =  Spree::Store.find(params[:store_id]).products.first
            if product
              serializer = Spree::V2::Storefront::IframeProductSerializer.new(product)
              render json: serializer.serializable_hash, status: :ok
            else
              render json: { error: "No products found" }, status: :not_found
            end
          end

          def trashbin
            if @products.update_all(trashbin: true)
              ReindexProductsWorker.perform_async(@products.ids)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@products).error)
            end
          end

          def reinstate
            if @products.update_all(trashbin: false)
              ReindexProductsWorker.perform_async(@products.ids)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@products).error)
            end
          end

          def change_status
            @products.each do |product|
              if product.status == "active"
              product.draft
              elsif product.status == "draft"
                product.activate
              end
            end
            render_serialized_payload { success({success: true}).value }
          end

          def approved
            if @products.each  { |product| product.activate }
              # create product currency prices on approved product
              Searchkick.callbacks(:bulk) {
                @products.find_each { |product| ProductPricesWorker.perform_async(product.id) }
              }
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@products).error)
            end
          end

          def pending
            if @products.each  { |product| product.draft }
              ReindexProductsWorker.perform_async(@products.ids)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@products).error)
            end
          end
          
          def destroy_multiple
            if @products.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@products).error)
            end
          rescue Exception => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def get_filters
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            filters = Spree::Product.side_filters(params, storefront_current_client, spree_current_store)
            render json: filters.to_json
          end

          private

          def destory_already_present_properties
            @product.product_properties.destroy_all
          rescue Exception => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def update_stock_items product
            stock_obj = product.stock_items.first
            stock_obj.count_on_hand = params[:stock_qty].to_i
            stock_obj.save
          end

          def create_variants(variants, product)
            variants.each do |variant|
              variant.merge!(parent_variant_id: variant[:id])
              variant.delete("id")
              next if variant["archived"] == "true"
              var_quantity = variant.delete("quantity")
              variant.permit!
              var = product.variants.new(variant)
              var.save(:validate => false)
              # var = product.variants.create(variant)
              stock_obj = var.stock_items.first
              if stock_obj && !product.linked
                stock_obj.count_on_hand = var_quantity.to_i
                stock_obj.save
              end
            end
          end

          def update_variants(variants, product)
            present_product_variants = product.variant_ids
            selected_variants = variants.map{|v| v["id"].to_i if v["id"].present?}.compact
            variants_need_to_del = present_product_variants - selected_variants
            variants.each do |variant|
              variant_id = variant["id"]
              var_quantity = variant.delete("quantity")
              variant.permit!
              if variant_id.present?
                existed_variant = product.variants.where(id: variant_id.to_i).first
                existed_variant.attributes =  variant
                existed_variant.save(:validate => false)
              else
                next if variant["archived"] == "true"
                existed_variant = product.variants.new(variant)
                existed_variant.save(:validate => false)
                # existed_variant = product.variants.create(variant)
              end
              stock_obj = existed_variant.stock_items.first
              if stock_obj && !product.linked
                stock_obj.count_on_hand = var_quantity.to_i
                stock_obj.save
              end
            end
            product.variants.where(id: variants_need_to_del).delete_all
            product.variants.where(archived: true).each do |variant|
              next unless variant.images.present?
              variant.images.update_all(viewable_id: product.master.id)
            end
          end

          def set_products
            @products = Spree::Product.accessible_by(current_ability).where('spree_products.id IN (?)', JSON.parse(params[:ids]))
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @products&.any?
          end

          def set_admin_products
            @products = get_product_by_role&.where('spree_products.id IN (?)', JSON.parse(params[:ids]))
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @products&.any?
          end

          def set_product
            @product = get_product_by_role&.friendly&.find(params[:id])
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @product
          end

          def valid_json?(json)
            begin
              JSON.parse(json)
              return true
            rescue Exception => e
              return false
            end
          end

          def sorted_collection(collection)
            params[:client_id] = storefront_current_client&.id
            collection_sorter.new(collection, params, current_currency).call
          end

          def collection_sorter
            Spree::Api::Dependencies.storefront_products_sorter.constantize
          end

          def serialize_collection(collection, classified_collection = nil)
            collection_serializer.new(
              collection,
              collection_options((classified_collection || collection)),
            ).serializable_hash
          end

          def serialize_listing(collection, classified_collection = nil)
            Spree::V2::Storefront::ProductListingSerializer.new(
              collection,
              collection_options((classified_collection || collection)),
            ).serializable_hash
          end

          def serialize_vendor_products_collection(collection)
            collection_serializer.new(
                collection,
                collection_options(collection),
                ).serializable_hash
          end

          def serialize_resource(resource)
            store_id = request.headers["X-Store-Id"]
            store_id_params =   spree_current_store.id if store_id
            allow_store_ids = []
            allow_store_ids = @spree_current_user&.allow_store_ids if @spree_current_user.present? && @spree_current_user.user_with_role("sub_client")
            default_currency = (request.headers['X-Currency'].blank? ? resource.vendor.try(:base_currency).try(:name) : current_currency)
            resource_serializer.new(
              resource,
              include: resource_includes,
              params: {
                default_currency: default_currency,
                store: spree_current_store,
                store_id: store_id_params,
                followee_user_id: @spree_current_user&.id,
                allow_store_ids: allow_store_ids

              }
            ).serializable_hash
          end

          def resource
            if @spree_current_user.present?
              if @spree_current_user.spree_roles.map(&:name).include? "vendor"
                @spree_current_user.vendors.first.products.untrashed.friendly.find(params[:id])
              elsif @spree_current_user.spree_roles.map(&:name).include? "admin"
                Spree::Product.friendly.find(params[:id])
              elsif (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
                current_client.products.friendly.find(params[:id])
              elsif @spree_current_user.spree_roles.map(&:name).include? "customer"
                spree_current_store.products.friendly.find(params[:id])
              end
            else
              spree_current_store.products.friendly.find(params[:id])
            end
          end

          def related_product_collection(related_collection, vendor_collection)
            {
              related_products: collection_serializer.new(related_collection, collection_options_no_link(related_collection)).serializable_hash,
              vendor_products: collection_serializer.new(vendor_collection, collection_options_no_link(vendor_collection)).serializable_hash
            }
          end

          def serialize_image_collection(collection)
            Spree::V2::Storefront::ImageSerializer.new(collection).serializable_hash
          end

          def serialize_option_type_collection(collection)
            Spree::V2::Storefront::OptionTypeSerializer.new(collection).serializable_hash
          end

          def serialize_personlization_collection(collection)
            Spree::V2::Storefront::PersonalizationSerializer.new(collection).serializable_hash
          end

          def serialize_store_collection(collection)
            Spree::V2::Storefront::StoreSerializer.new(
                collection,
               {
                   fields: sparse_fields
               }).serializable_hash
          end

          def serialize_properties_collection(collection)
            Spree::V2::Storefront::PropertySerializer.new(collection).serializable_hash
          end

          def collection_serializer
            Spree::Api::Dependencies.storefront_product_serializer.constantize
          end

          def resource_serializer
            Spree::Api::Dependencies.storefront_product_serializer.constantize
          end

          def collection_options_no_link(collection)
            {
              params: {
                default_currency: current_currency,
                store: spree_current_store
              }
            }
          end

          def collection_options(collection)
            {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: resource_includes,
              fields: sparse_fields,
              params: {
                default_currency: current_currency,
                store: spree_current_store,
                user: spree_current_user
              }
            }
          end

          def product_params
            params.require(:product).permit(:track_inventory, :barcode_number, :unit_cost_price,:enable_product_info,:send_gift_card_via, :brand_name, :recipient_email_link, :recipient_details_on_detail_page, :linked, :voucher_email_image, :intimation_emails, :disable_quantity, :default_quantity, :hide_from_search, :campaign_code, :ts_type, :digital_service_provider, :prefix, :suffix, :vendor_id, :tax_category_id, :rrp, :minimum_order_quantity, :pack_size, :product_is_gift_card, :delivery_details, :delivery_mode, :name, :description, :vendor_sku, :stock_status, :sale_price, :long_description, :meta_description, :meta_keywords, :manufacturing_lead_time, :restricted_area_delivery,
              :delivery_days_to_same_country, :delivery_days_to_americas, :delivery_days_to_africa, :delivery_days_to_australia, :delivery_days_to_asia, :delivery_days_to_europe, :single_page,
              :delivery_days_to_restricted_area,  :meta_title, :category_state, :shipping_category_id, :local_area_delivery, :wide_area_delivery, :featured, :gift_messages, :price, :on_sale, :sale_start_date, :sale_end_date, :product_type, :daily_stock, :digital, blocked_dates: [:start_date, :end_date], product_properties_attributes: [:id, :value, :property_id, :_destroy],
              customizations_attributes: [:id, :show_price, :label, :order,  :field_type, :max_characters, :is_required, :_destroy, :store_ids => [], :customization_options_attributes => [:id, :label, :color_code,
              :max_characters, :value, :sku, :price, :_destroy]], :info_product_attributes => [:id, :banner_overlay_text, :info_introduction, :heading_product_description, :media_url, :info_description, :info_price_statement, :book_experience_url, :show_send_gift_card_button, :curated_by, :last_block, :_destroy, :media_type], tag_list: [])

          end


          def can_manage_update_stock?(object)
            if spree_current_user.has_spree_role?(:client) || spree_current_user.has_spree_role?(:sub_client)
              return (object&.client_id == spree_current_user&.client_id)
            elsif spree_current_user.has_spree_role?(:vendor)
              return (spree_current_user.vendor_ids.include?(object.vendor_id) && object.client_id == spree_current_user.vendors.last.client_id)
            end
          end

          def can_manage_import_stock?(object)
            if spree_current_user.has_spree_role?(:client) || spree_current_user.has_spree_role?(:sub_client)
              return (object&.product&.client_id == spree_current_user&.client_id)
            elsif spree_current_user.has_spree_role?(:vendor)
              return (spree_current_user&.vendor_ids&.include?(object&.vendor_id) && object&.product.client_id == spree_current_user.vendors.last.client_id)
            end
          end

          def get_product_by_role
            if @spree_current_user&.has_spree_role?(:vendor)
              return @spree_current_user.vendors.first&.products
            elsif @spree_current_user&.has_spree_role?(:client) || @spree_current_user&.has_spree_role?(:sub_client)
              return current_client&.products
            end            
          end
        end
      end
    end
  end
end
