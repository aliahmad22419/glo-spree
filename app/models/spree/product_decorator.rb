require 'soap/wsdlDriver'
require "csv"
module Spree
  module ProductDecorator

    def self.prepended(base)
      base.include Exchangeable
      base.include ProductSearch
      # include SharedMethods
      base.include InventoryCallbacks
      base.include Spree::Webhooks::HasWebhooks

      base.acts_as_taggable_on :tags
      base.acts_as_taggable_tenant :client_id
      base.friendly_id :sku_slug, slug_column: :slug, use: :history
      base.has_many :variant_images, -> { order(:position) }, source: :images, through: :variants_including_master
      base.has_one :info_product, dependent: :destroy, :class_name => 'Spree::InfoProduct'
      base.preference :terms_and_conditions, :text, default: ''
      base.preference :is_weighted, :boolean, default: false
      base.preference :product_weight, :float, default: 0
      base.preference :maximum_order_quantity, :integer, default: 0


      attr_accessor :selected_taxon_ids
      base.enum voucher_email_image: { product_image: 0, generic_image: 1 }
      base.enum send_gift_card_via: { sms: 0, email: 1, both: 2 }

      base.after_commit ->(product){ product.variants_including_master.update_all(track_inventory: product.track_inventory) }
      base.after_create :update_slug_history
      base.before_save :calculate_delivery_days#, :ensure_vendor_base_currency
      base.after_save :update_classification_on_store_basis, :set_swatches
      base.after_commit :update_product_currency_prices, if: :changed_prices?
      base.after_commit -> (obj) { obj.reindex }
      base.after_update :update_variants_vendor, :update_variants_stock_location, :expire_cart_token, if: Proc.new{|product| product.previous_changes.key?("vendor_id") }
      base.after_commit :update_variant_images
      base.after_commit :auto_approve, on: :create
      base.after_save :sync_daily_stock_products, if: :daily_stock?
      base.validates :vendor, presence: true
      base.validate :maximum_order_quantity_range

      base.has_many :questions, dependent: :destroy, :class_name => 'Spree::Question'
      base.has_many :customizations, dependent: :destroy, :class_name => 'Spree::Customization'
      base.has_many :product_currency_prices, dependent: :destroy, :class_name => 'Spree::ProductCurrencyPrice'
      base.has_many :stock_products, dependent: :destroy, :class_name => 'Spree::StockProduct', foreign_key: :parent_id
      base.has_many :daily_stock_items, through: :stock_products, source: :stock_items
      base.has_many :product_batches
      base.has_one_attached :banner_image

      base.accepts_nested_attributes_for :customizations, allow_destroy: true
      base.accepts_nested_attributes_for :product_properties, allow_destroy: true
      base.accepts_nested_attributes_for :info_product, allow_destroy: true
      base.has_and_belongs_to_many :stores, join_table: 'spree_products_stores'

      base.scope :by_store, -> (store) { joins(:stores).where(spree_products_stores: { store_id: store }) }
      base.scope :sku_cont, -> (sku) { joins(:variants_including_master).where('spree_variants.sku ILIKE ?', "%#{sku.to_s}%")}
      base.scope :quantity_from_cont, -> (from) { joins(:stock_items).group("spree_products.id").having("sum(spree_stock_items.count_on_hand) >= #{from}")}
      base.scope :quantity_to_cont, -> (to) { joins(:stock_items).group("spree_products.id").having("sum(spree_stock_items.count_on_hand) <= #{to}")}
      base.scope :recently_viewed, -> (recent_ids) { where("id IN (?)", recent_ids) }
      base.scope :trashed, -> { where(trashbin: true) }
      base.scope :untrashed, -> { where(trashbin: false) }
      base.scope :active_vendor_products, -> { joins(:vendor).where("(spree_vendors.state != ?) AND (spree_vendors.vacation_mode IS NULL OR spree_vendors.vacation_mode = ?) AND (spree_vendors.agreed_to_client_terms = ?) AND ((spree_vendors.vacation_start IS NULL OR spree_vendors.vacation_start < ?) OR (spree_vendors.vacation_end IS NULL OR spree_vendors.vacation_end > ?))", 'blocked', false, true, Date.today, Date.today) }
      base.scope :in_stock_status, -> { where(stock_status: true) }
      base.scope :product_quantity_count, -> { where("(spree_products.track_inventory = 'false') OR (spree_products.count_on_hand > 0 AND spree_products.track_inventory='true')") }
      base.scope :approved, -> { where(status: "active") }
      base.scope :not_hide_from_search, -> { where(hide_from_search: false) }
      base.scope :expired_sale_products, -> { where("on_sale = ? AND sale_end_date < ?", true, Date.today)}
      base.scope :sale_start_today, -> { where("on_sale = ? AND sale_start_date = ?", true, Date.today)}
      base.scope :linked, -> { where(linked: true) }
      base.scope :excluding_daily_stock, -> { where(type: nil) }
      base.after_commit :flush_cache

      base.whitelisted_ransackable_associations = %w[stores variants_including_master master variants vendor taxons product_properties]
      base.whitelisted_ransackable_attributes = %w[
        id name status trashbin vendor_sku price vendor_id meta_keywords
        calculated_days_to_same_country calculated_days_to_restricted_area calculated_days_to_asia type effective_date
        calculated_days_to_africa calculated_days_to_americas calculated_days_to_europe calculated_days_to_australia created_at
      ]
      base.whitelisted_ransackable_scopes = %w[check_on_sale not_discontinued sku_cont quantity_from_cont quantity_to_cont get_stock_status_products price_between property_filters price_between_with_currency]
    end

    RESTRICTED_AREAS = [ "China", "Indonesia", "United Arab Emirates" ]  unless const_defined?(:RESTRICTED_AREAS)
    REGIONS = [:asia, :africa, :australia, :europe, :americas, :restricted_area, :same_country] unless const_defined?(:REGIONS)

    def flush_cache
      key ="#{self.slug}"
      Rails.cache.redis.keys.each do |cache|
        value = cache.include?(key)
        Rails.cache.delete(cache) if value
      end
    end

    def maximum_order_quantity_range
      errors.add(:maximum_order_quantity, 'Maximum order quantity is out of range with limit 4 bytes') if preferences[:maximum_order_quantity] > 2_147_483_647
    end

    def self.available(available_on = nil, currency = nil)
      if available_on
        scope = not_discontinued.where("#{Product.quoted_table_name}.available_on <= ?", available_on)
      else
        scope = where(status: 'active')
      end

      unless Spree::Config.show_products_without_price
        currency ||= Spree::Config[:currency]
        scope = scope.with_currency(currency)
      end

      scope
    end

    def available?
      !(available_on.nil? || available_on.future?) && !deleted? && !discontinued?
    end

    def update_variant_images
      if Rails.env.production?
        StoreProductImageVariantWorker.perform_async(self.id, 'product')
      end
    end

    def auto_approve
      if self.client.auto_approve_products
        self.update_column(:status, "active")
        update_product_currency_prices
      end
    end

    def update_variants_vendor
      self.variants_including_master.update_all(vendor_id: self.vendor_id)
    end

    def expire_cart_token
      orders_ids = []
      conflicted_items = Spree::LineItem.joins(:order,:variant).where("(spree_line_items.variant_id IN (?) AND spree_line_items.vendor_id <> spree_variants.vendor_id) AND spree_orders.completed_at IS NULL", self.variants_including_master.ids)
      conflicted_items.each do |conflicted_item|
        conflicted_item.update(vendor_id: conflicted_item.variant.vendor_id, vendor_name: conflicted_item.variant.vendor.name)
        next if orders_ids.include?(conflicted_item.order_id)
        conflicted_item.order.generate_cart_token
        orders_ids.push(conflicted_item.order_id)
      end
    end

    def update_variants_stock_location
      stock_location_id = self.vendor.stock_location_ids&.first
      self.stock_items.update_all(stock_location_id: stock_location_id)
    end

    def update_classification_on_store_basis
      selected_taxon_ids&.compact!
      classifications.where("store_id NOT IN (?) OR taxon_id NOT IN (?)", store_ids, selected_taxon_ids).destroy_all
      return if selected_taxon_ids.blank? || store_ids.blank?

      selected_taxon_ids.each do |t_id|
        self.store_ids.each do |s_id|
          classifications.find_or_create_by(taxon_id: t_id,
                                store_id: s_id)
        end
      end
    end

    def persist_count_on_hand
      self.count_on_hand = total_on_hand.to_s.to_i
      self.save
    end

    def total_on_hand
      if any_variants_not_track_inventory?
        Float::INFINITY
      else
        Spree::StockItem.where(variant_id: master_or_variants.ids).sum(&:count_on_hand)
      end
    end

    def calculate_delivery_days
      mlt = (manufacturing_lead_time || 1)
      REGIONS.each do |region|
        days = send("delivery_days_to_#{region}").to_f
        send("calculated_days_to_#{region}=", (0.66 * (days + mlt)).round)
      end
    end

    def sku_slug
      if url_key.present?
        url_key.to_s
      else
        "#{name}-#{master.sku}".parameterize
      end
    end

    def should_generate_new_friendly_id?
      true
    end


    # def self.price_between_with_currency(low, high, default_currency)
    #   product_ids = []
    #   Spree::Product.all.map do |p|
    #     price_after_rates = p.product_price(default_currency, nil)
    #     product_ids.push p.id if price_after_rates.to_f >= low && price_after_rates.to_f <= high
    #   end
    #   return where(id: product_ids)
    # end

    def delivery_days(store)
      days = self.manufacturing_lead_time.to_f
      statement = Date.today

      source = self.vendor&.ship_address&.country&.name
      is_same_region = (source.blank? || store.blank? || (source == store&.name))

      statement += if is_same_region
        days += delivery_days_to_same_country.to_f if delivery_days_to_same_country.present?
        days
      # elsif RESTRICTED_AREAS.include?(store&.name)
      #   days += delivery_days_to_restricted_area.to_f
      #   delivery_days_to_restricted_area.to_f
      else
        country = Spree::Country.find_by_name(store.name)
        zone = country.zones.first&.name if country.present?
        return nil unless zone.present? # cannot deliver to undefined zone

        zone_days = (self.send("delivery_days_to_#{zone&.downcase}").to_f rescue 0)
        days += zone_days
        zone_days
      end

      return {
        date: statement.strftime("#{statement.day.ordinalize} %B %Y"),
        standard: "#{(0.66 * days).round} - #{days.round}",
        courier:  "#{(days / 3.0).round} - #{(days / 2.0).round}"
      }
    end

    def delivery_charges(store)
      local_store_ids = if vendor.present?
        vendor.local_store_ids
      else
        []
      end

      return (local_area_delivery || 0) if local_store_ids.include?(store&.id&.to_s)
      (wide_area_delivery || 0)
    end

    def on_sale?
      on_sale && ((sale_start_date <= Date.today && sale_end_date >= Date.today) rescue false)
    end

    def price_with_delivery_charges store
      @store = store
      return ((on_sale? ? sale_price.to_f : 0) + delivery_charges(store))
    end


    def update_images(images_ids,deleted_images_ids)
      if images_ids.present?
        images = Spree::Image.where(id: images_ids.keys)

        images.each do |img|
          thumnalis_data = images_ids[img.id.to_s]
          unless thumnalis_data["variant_id"].blank? || daily_stock?
            thumnalis_data["viewable_id"] = thumnalis_data["variant_id"]
          else
            thumnalis_data["viewable_id"] = master.id
          end
          if thumnalis_data["is_duplicate"]
            dup_img = Spree::Image.new()
            variant = self.variants_including_master.find_by_parent_variant_id(img.viewable_id) || self.master
            dup_img.viewable_id = variant.id
            dup_img.attachment.attach(img&.attachment.blob)
            dup_img.save
            dup_img.update(viewable_type: "Spree::Variant", attachment_file_name: img.attachment_file_name, small_image: thumnalis_data["small_image"].nil? ? false : thumnalis_data["small_image"], base_image: thumnalis_data["base_image"].nil? ? false : thumnalis_data["base_image"], thumbnail: thumnalis_data["thumbnail"].nil? ? false : thumnalis_data["thumbnail"], sort_order: thumnalis_data["sort_order"] , sort_order_info_product: (thumnalis_data["sort_order_info_product"].present? ? thumnalis_data["sort_order_info_product"] : dup_img.sort_order_info_product) , alt: thumnalis_data["alt"])
          else
            img.update(small_image: thumnalis_data["small_image"].nil? ? false : thumnalis_data["small_image"], base_image: thumnalis_data["base_image"].nil? ? false : thumnalis_data["base_image"], thumbnail: thumnalis_data["thumbnail"].nil? ? false : thumnalis_data["thumbnail"], viewable_id: thumnalis_data["viewable_id"], sort_order: thumnalis_data["sort_order"], sort_order_info_product: (thumnalis_data["sort_order_info_product"].present? ? thumnalis_data["sort_order_info_product"] : img.sort_order_info_product), alt: thumnalis_data["alt"])
          end
        end
      end
      Spree::Image.where(id: deleted_images_ids).delete_all if deleted_images_ids.present?
    end

    def custom_price_min_max(store=nil, currency_price=nil)
      return { min: 0.0, max: 0.0 } unless store.present?

      min, max = store.min_custom_price.to_f, store.max_custom_price.to_f
      if currency_price.present? && store.preferred_custom_amount_exchangeable
        min *= currency_price.exchange_rate_value
        max *= currency_price.exchange_rate_value
      end

      { min: min.to_i, max: max.to_i }
    end

    def price_values(default_currency=nil, store=nil)
      @store = store
      default_currency ||= (vendor&.base_currency&.name || "USD")
      currency_price = product_currency_prices.in_currency(default_currency)[0]

      # Details (exchange rate applied)
      # {
      #   price: base price,
      #   sale_price: sale price,
      #   local_area_delivery: delivery charges(local/wide),
      #   base_price: price including delivery charges,
      #   final_price: it's = sale_price + delivery charges if on_sale otherwise price + delivery charges
      # }

      return {
        price: 0, sale_price: 0, local_area_delivery: 0, local_area_delivery_price: 0, wide_area_delivery_price: 0,
        base_price: 0, final_price: 0, rrp: 0, tax: { amount: 0.0, rate: 0.0 }, custom_price_range: { min: 0.0, max: 0.0 }
      } if currency_price.blank?

      return {
        price: tp(currency_price.price, default_currency),
        sale_price: tp((on_sale? ? tp(currency_price.sale_price) : 0), default_currency),
        local_area_delivery: tp(currency_price.delivery_charges(store.try(:id).to_s), default_currency),
        local_area_delivery_price: tp(local_area_delivery, default_currency),
        wide_area_delivery_price: tp(wide_area_delivery, default_currency),
        base_price: tp((currency_price.delivery_charges(store.try(:id).to_s) + currency_price.price), default_currency),
        final_price: tp(currency_price.product_final_price(store.try(:id).to_s), default_currency),
        rrp: tp(rrp, default_currency),
        tax: calculated_tax(default_currency, store.try(:id)),
        custom_price_range: custom_price_min_max(@store, currency_price)
      }
    end

    def price_in_currency(default_currency=nil, store=nil)
      @store = store
      default_currency ||= (vendor&.base_currency&.name || "USD")
      currency_price = product_currency_prices.in_currency(default_currency)[0]
      return nil if currency_price.blank?

      tp(currency_price.product_final_price(store.try(:id).to_s), default_currency)
    end

    def product_price(default_currency, store)
      @store = store
      tp(price_with_delivery_charges(store) * exchange_rate(default_currency), default_currency)
    end

    def calculated_tax(default_currency, store_id)
      currency_price = product_currency_prices.in_currency(default_currency)[0]
      return { amount: 0.0, rate: 0.0 } if currency_price.blank?

      currency_price.calculated_tax(store_id)
    end

    class << self
      def get_stock_status_products(status)
        if status == "in_stock"
          joins(:stock_items).group("spree_products.id").having("sum(spree_stock_items.count_on_hand) > 0")
        else
          joins(:stock_items).group("spree_products.id").having("sum(spree_stock_items.count_on_hand) <= 0")
        end
      end

      def check_on_sale(on_sale)
        if on_sale == 'yes'
          where("spree_products.on_sale = true AND sale_start_date <= ? AND sale_end_date >= ?", Date.today, Date.today)
        elsif 'no'
          where("spree_products.on_sale = false OR sale_start_date > ? OR sale_end_date < ?", Date.today, Date.today)
        end
      end

      def delivery_filter(products, store)
        country = store.client.countries.find_by(name: store.name) rescue nil
        zone = country.zones.first&.name if country.present?
        return [] if zone.blank?
        filter_values = products.map { |product| product.send("calculated_days_to_#{zone.downcase}").to_s }
        filter_values = filter_values.compact.uniq - ["0"] - ["1"]
        filter_values.sort!
      end

      def property_filters(filters = {}, code)
        delivery_products = []
        if filters[:de].present?
          delivery = filters[:de]
          store = Spree::Store.find_by(code: code)

          country = Spree::Country.find_by_name(store&.name)
          zone = country.zones.first&.name if country.present?
          # cannot deliver to undefined zone
          delivery_products = if zone.blank?
                                []
                              else
                                params = { "calculated_days_to_#{zone.downcase}_in": delivery }
                                Spree::Product.untrashed.active_vendor_products.in_stock_status.product_quantity_count.ransack(params).result.ids
                              end
        end

        filtered_products = {}
        filters.each do |property_id, filter_values|
          next if property_id == "de"
          filtered_products[property_id] = Spree::ProductProperty.where(value: filter_values, property_id: property_id.to_i).pluck(:product_id)
        end
        filtered_products["de"] = delivery_products if filters[:de].present?

        first_item = true
        product_ids = []

        filtered_products.each do |property_id, products_ids_array|
          if first_item
            product_ids = products_ids_array
          else
            product_ids = product_ids & products_ids_array
          end
          first_item = false
        end
        return where(id: product_ids.uniq)
      end

      def price_between_with_currency(params, store, vendor_ids)
        store_country = Spree::Country.find_by(id: store.country_ids[0])
        restricted_area_ids = Spree::Country.where(name: RESTRICTED_AREAS).ids
        low, high, default_currency = params

        # products = self.joins(:product_currency_prices)#.where("spree_product_currency_prices.to_currency = ?", default_currency)
        if store&.country_specific
          select("DISTINCT spree_products.*, prices.calculated_price as calculated_price").joins("INNER JOIN (
            SELECT vendor_id, product_id,
            CASE
              WHEN spree_product_currency_prices.vendor_country_id = #{store_country&.id} THEN spree_product_currency_prices.local_area_price
              WHEN spree_product_currency_prices.vendor_country_id IN (#{restricted_area_ids.join(',')}) THEN spree_product_currency_prices.restricted_area_price
              ELSE spree_product_currency_prices.wide_area_price
            END calculated_price
            FROM public.spree_product_currency_prices
            WHERE to_currency = '#{default_currency}'
            AND vendor_id IN (#{vendor_ids.join(',')})
          ) prices on spree_products.id = prices.product_id")
          .where("prices.calculated_price BETWEEN ? AND ?", low, high)
          .order("calculated_price DESC")
        else
          joins(:product_currency_prices).where("spree_product_currency_prices.to_currency = ? AND spree_product_currency_prices.price BETWEEN ? AND ?", default_currency, low, high)
          .order("spree_product_currency_prices.price DESC")
        end
      end

      def side_filters(params, storefront_current_client, spree_current_store, products=nil)
        options = { store_id: spree_current_store.id, default_currency: params["currency"] }

        unless products.present?
          if params[:q].present?
            params[:q].delete("stores_id_eq")
            # options[:property_filters] = params[:q][:property_filters][0].to_unsafe_h
            options[:taxon_permalink] = params[:q].delete("taxons_permalink_eq")
            options[:vendor_slug] = params[:q].delete("vendor_slug_eq")
            options[:taxon_id] = storefront_current_client.taxons.where(permalink: options[:taxon_permalink]).select("id").pluck(:id)
            # options[:price_filter_values] = params[:q].delete("price_between_with_currency")
            options[:sort] = "-price"
            options[:active_vendor_ids] = storefront_current_client.vendors.active.select("id").pluck(:id)
            decoded_term = params[:q].delete(:name_or_brand_name_or_vendor_name_or_vendor_sku_or_meta_keywords_cont)
            decoded_term ||= ""
            begin
              decoded_term = URI.decode(decoded_term)
            end while(decoded_term != URI.decode(decoded_term))
            options[:search_term] = decoded_term
          end
          # q = storefront_current_client.products.ransack(params[:q])
          # products = q.result
          products, _ = Spree::Product.searche(spree_current_store, options, params)
        end
        filters = []
        products = [] if products.blank?
        product_ids = products.map(&:id)

        if options[:taxon_permalink].present?
          sub_categories_values = storefront_current_client.taxons.where(permalink: options[:taxon_permalink]).first&.children
                                                            &.joins(classifications: :product)
                                                            &.where('spree_products_taxons.store_id = ?
                                                                    AND spree_products.status = ?
                                                                    AND spree_products.trashbin = ?
                                                                    AND spree_products.stock_status = ?
                                                                    AND spree_products.count_on_hand > ?
                                                                    AND spree_products.hide_from_search = ?',
                                                                    spree_current_store.id, 'active', false, true, 0, false)
                                                            &.pluck('id', 'name', 'permalink')&.uniq

          if sub_categories_values.present?
            sub_categories_hash = {}
            sub_categories_hash["name"] = "sub_categories"
            sub_categories_hash["attribute"] = "taxons_permalink_eq"
            sub_categories_hash["label"] = "Sub-category"
            sub_categories_hash["values"] = sub_categories_values.map do |id, name, permalink|{ id: id, name: name, permalink: permalink} end
            filters.push(sub_categories_hash)
          end
        end

        properties = spree_current_store.properties.where(filterable: true)

        if properties.present?
          properties.each do |pro|
            product_properties = pro.product_properties.where(product_id: product_ids)
            properties_values = product_properties.present? ? product_properties.map(&:value).reject { |c| c.empty? }.uniq : []
            next if properties_values.blank?
            product_property_hash = {}
            product_property_hash["name"] = "product_#{pro.name}"
            product_property_hash["attribute"] = "property_filters"
            product_property_hash["id"] = pro.id
            product_property_hash["label"] = "#{pro.name.titleize}"
            product_property_hash["values"] = properties_values.sort
            filters.push(product_property_hash)
          end
        end

        # maximum_price_product = products.joins(master: :default_price).order("spree_prices.amount DESC").first
        # maximum_price = maximum_price_product&.price || 0
        maximum_price_product = products[0].product_currency_prices.find_by(to_currency: options[:default_currency]) rescue nil
        maximum_price = if maximum_price_product.present?
                          (maximum_price_product.local_store_ids.include?(spree_current_store.id.to_s) ?
                          maximum_price_product.local_area_price : maximum_price_product.wide_area_price) + maximum_price_product.calculated_tax(options[:store_id])[:amount]
                        end
        # maximum_price = maximum_price_product.product_price(current_currency, spree_current_store).to_f if maximum_price_product.present?
        # selected_products = []
        # products.group_by(&:vendor_id).each{|id, pros| selected_products.push(pros.min_by(&:price)); selected_products.push(pros.max_by(&:price))}
        # prices = selected_products.map{|product| product.product_price(current_currency, spree_current_store).to_f}
        # product_delivery_values = Spree::Product.delivery_filter(products, spree_current_store).sort_by(&:to_i)
        product_delivery_values = ["3","4","5","6","7","9","10","11","12","13","14","15","16","17","18","19","20","23","255"]
        if product_delivery_values.present?
          product_delivery = {}
          product_delivery["name"] = "product_Delivery"
          product_delivery["id"] = "de"
          product_delivery["attribute"] = "property_filters"
          product_delivery["label"] = "Delivery Within"
          product_delivery["values"] = product_delivery_values
          filters.push(product_delivery)
        end

        product_prices_hash = {}
        product_prices_hash["name"] = "product_prices"
        product_prices_hash["attribute"] = "price_between"
        product_prices_hash["label"] = "Price"
        product_prices_hash["values"] = [{min: 0 }, {max: (maximum_price.ceil rescue 0) }]
        filters.push(product_prices_hash)
        return filters
      end

    end

    def self.generate_product_csv_for_stores
      stores = Spree::Store.all
      headers = ["sku",	"merchantProductId",	"price",	"link",	"image1",	"title",	"description",	"brand",	"merchantCategoryName",	"salePrice",	"stockQuantity",	"adult",	"ageGroup",	"available",	"availableEnd",	"availableStart",	"color",	"condition",	"country",	"currency",	"descriptionHtml",	"ean", 	"Gender",	"gtin",	"highlights",	"highlightsHtml",	"isbn",	"itemHeight",	"itemHeightUnit",	"itemLength",	"itemLengthUnit",	"itemWidth",	"itemWidthUnit",	"language",	"manufacturer",	"material",	"merchantVariantId",	"mobileLink",	"mpn",	"optionTitle",	"packageContent",	"packageContentHtml",	"packageHeight",	"packageHeightUnit",	"packageLength",	"packageLengthUnit",	"packageWidth",	"packageWidthUnit",	"parentSku",	"publish",	"saleEnd",	"saleId",	"saleName",	"saleStart",	"searchTerms",	"shippingCost",	"shippingNumber",	"shippingType",	"shortDescription",	"shortDescriptionHtml",	"size",	"size System",	"specifications",	"specificationsHtml",	"upc",	"variantTitle",	"vendor",	"warrantyPeriod",	"warrantyUnit",	"weight",	"weightUnit", "image2",	"image3",	"image4",	"image5",	"image6",	"image7",	"image8",	"image9" ]
      stores.each do |store|
        store_code = store.name == "Singapore"? "" : store.code
        CSV.open("public/product_csv/#{store.name.parameterize}-products.csv", "wb") do |csv|
          csv << headers
          store.products.each do |p|
            product_link = "https://giftslessordinary.com#{store_code.present? ? "/" + store_code : ""}/#{p.slug}"
            base_image = p.images.where(base_image: true).first.present? ? p.images.where(base_image: true).first : ""
            image1 = base_image.present? ? "https://glo.techsembly.com" + base_image.styles.last[:url] : ""
            small_image = p.images.where(small_image: true).first.present? ? p.images.where(small_image: true).first : ""
            small_image_url = small_image.present? ? "https://glo.techsembly.com" + small_image.styles.last[:url] : ""
            thumnail = p.images.where(thumbnail: true).first.present? ? p.images.where(thumbnail: true).first : ""
            thumbnail_url = thumnail.present? ? "https://glo.techsembly.com" + thumnail.styles.last[:url] : ""
            long_description = ActionView::Base.full_sanitizer.sanitize(p.long_description)
            short_description = ActionView::Base.full_sanitizer.sanitize(p.description)
            brand = p.vendor.present? ? p.vendor.name : ""
            categories = p.taxons.present? ? p.taxons.pluck(:permalink).map{|t| t.split("/")}.max_by(&:length).map{|w| w.titleize}.join(" ") : ""
            vendor_base_currency = ""
            if p.vendor.present?
              vendor_base_currency = p.vendor.base_currency.present? ? p.vendor.base_currency.name : ""
            end
            vendor_sku = p.vendor.present? ? p.vendor.sku : ""
            extra_imge_array = []
            p.images.where(base_image: false, small_image: false, thumbnail: false).each do |img|
              extra_imge_array.push("https://glo.techsembly.com" + img.styles.last[:url])
            end
            data_arr = [p.sku, p.vendor_sku, p.price, product_link, image1, p.name, long_description, brand, categories,
                        p.sale_price, p.total_on_hand, "n/a", "n/a", p.stock_status, "n/a", "n/a", "n/a", "new", store.name,
                        vendor_base_currency, p.long_description, "n/a", "n/a","n/a","n/a","n/a","n/a","n/a","n/a","n/a","n/a",
                        "n/a","n/a","n/a", brand, "n/a", p.variants.present? ? vendor_sku : "", "n/a", "n/a", "n/a", "n/a", "n/a", "n/a", "n/a", "n/a",
                        "n/a", "n/a", "n/a", p.sku, p.stock_status? ? 1: 0,  "n/a", "n/a", "n/a", "n/a", "n/a", 0, "n/a",
                        "n/a", short_description, p.description, "", "n/a", "n/a", "n/a", "n/a", p.variants.present? ? p.name : "",
                        brand, "n/a", "n/a", "n/a", "n/a", small_image_url, thumbnail_url] + extra_imge_array

            puts "data_arr"
            puts data_arr.count
            csv << data_arr
          end
        end
      end

    end

    def self.generate_product_csv
      headers = ["Name",	"Vendor Name",	"Shipping Zones",	"Product Stores",	"Product Shipping Category" ,	"Vendor Shipping Category"]
      vendor_zones = {}
      vendor_shipping_categoryes = {}
      client = Spree::Client.where(name: "njal").last
      client.vendors.each do |v|
        zones_arr = []
        shipping_categories_arr = []
        v.shipping_methods.each do |sm|
          zones_arr.push sm.zones.select("name").map(&:name)
          shipping_categories_arr.push sm.shipping_categories.select("name").map(&:name)
        end
        zones_arr = zones_arr.flatten.uniq
        shipping_categories_arr = shipping_categories_arr.flatten.uniq
        vendor_zones[v.id] = zones_arr.join(', ')
        vendor_shipping_categoryes[v.id] = shipping_categories_arr.join(', ')
      end
      CSV.open("public/product_csv.csv", "wb") do |csv|
        csv << headers
        client.products.each do |p|
          v_zones = ""
          v_zones = vendor_zones[p&.vendor&.id] if vendor_zones[p&.vendor&.id].present?
          v_cat = ""
          v_cat = vendor_shipping_categoryes[p&.vendor&.id] if vendor_shipping_categoryes[p&.vendor&.id].present?
          data_arr = [p.name, p&.vendor&.name, v_zones, p&.stores&.select("name").map(&:name).join(", "), p&.shipping_category&.name, v_cat]
          csv << data_arr
        end
      end
    end

    def self.import_apartment_number
      csv_url = "app/workers/appt.csv"
      csv_text = File.read(csv_url)

      csv = CSV.parse(csv_text, :headers => true)

      csv.each_with_index do |row, index|
        puts row["Email"]
        puts row["Shipping Addr First Name"]
        puts row["Shipping Addr Last Name"]
        puts row["Shipping Addr Address 1"]
        puts row["Shipping Addr Apt No"]
        orders  = Spree::Order.where(email: row["Email"].strip)
        orders.each do |o|
          ship_address = o.shipping_address
          next if ship_address.blank?
          next if row["Shipping Addr Apt No"].blank?
          if ship_address.firstname.strip == row["Shipping Addr First Name"].strip &&
              ship_address.lastname.strip == row["Shipping Addr Last Name"].strip &&
              ship_address.address1.strip == row["Shipping Addr Address 1"].strip
            ship_address.apartment_no = row["Shipping Addr Apt No"].strip
            ship_address.save
          end
        end
        puts "updated"
      end

    end

    def self.import_vendor_products
      csv_url = "app/workers/NewMalaysia.csv"
      csv_text = File.read(csv_url)

      csv = CSV.parse(csv_text, :headers => true)
      csv.each_with_index do |row, index|
        puts row["Email"]
        user = Spree::User.where(email: row["Email"].strip.downcase)&.first
        next if user.blank?
        vendor = user.vendors&.first
        next if vendor.blank?
        products = vendor.products
        store = Spree::Store.where(name: "Malaysia")&.first
        products.each do |p|
          puts "check for store"
          next if p.stores.include?store
          p.stores << store
          p.customizations.each do |cus|
            next if cus.store_ids.include?store.id.to_s
            cus.store_ids << store.id.to_s
            cus.save
          end
          puts "save store"
        end
      end
    end

    def tax_category
      super || client.tax_categories.find_by(is_default: true)
    end

    def set_swatches
      color_result = []
      size_result = []

      unless daily_stock?
        color_value = "color"
        size_value = "size"
        option_types_data = option_types.includes(:translations)
        color_ids = option_types_data.where('lower(spree_option_type_translations.name) = ?', color_value).ids
        size_ids = option_types_data.where('lower(spree_option_type_translations.name) = ?', size_value).ids
        variants.where(archived: false).each do |variant|
          next if variant&.stock_items&.first&.count_on_hand == 0
          color_option_values = variant.option_values.where(option_type_id: color_ids)
          color_option_values.each{|v| color_result.push v.name}
          size_option_values = variant.option_values.where(option_type_id: size_ids)
          size_option_values.each{|v| size_result.push v.name}
        end
      end

      self.update_column(:color_swatches, color_result)
      self.update_column(:size_swatches, size_result)
    end

    def email_thumbnail
      img =  images&.find_by(base_image: true)
      img ||= images.first
      image_url = img.active_storge_url(img.attachment) if img.present?
    end

    def master_or_variants
      nonmaster_variants = variants.unarchived

      nonmaster_variants.present? ? nonmaster_variants : Spree::Variant.where(id: master.id)
    end

    def image_urls
      base_img = self.images&.detect(&:base_image)
      small_img = self.images&.detect(&:small_image)
      thumbnail_img = self.images&.detect(&:thumbnail)
      default_img = self.images&.sort_by { |i| [i.sort_order, i.id] }&.reverse.first
      data = {
        base: base_img ? base_img.styles[3][:url] : nil,
        small: small_img ? small_img.styles[3][:url] : nil,
        thumbnail: thumbnail_img ? thumbnail_img.styles[3][:url] : nil,
        default: default_img ? default_img.styles[3][:url] : nil
      }
    end

    def set_master_variant_weight
      master.update_column(:weight, preferences[:product_weight])
    end

    def iframe_store_v3_flow_address(store)
      address = current_client.client_address.dup
      if address.save
        store.update_column(:v3_flow_address_id, address.id)
      end
    end

    private

    def update_product_currency_prices
      ProductPricesWorker.perform_async(id)
    end

    def changed_prices?
      ( saved_change_to_sale_price? || saved_change_to_tax_category_id? ||
        saved_change_to_local_area_delivery? || saved_change_to_wide_area_delivery? ||
        saved_change_to_restricted_area_delivery? || saved_change_to_on_sale? ||
        saved_change_to_sale_start_date? || saved_change_to_sale_end_date? ||
        saved_change_to_brand_name? || previous_changes.key?("vendor_id") )
    end

    def sync_daily_stock_products
      attrs = {}
      attrs[:blocked_dates] = blocked_dates if blocked_dates_previously_changed?
      attrs[:tax_category_id] = tax_category_id if tax_category_id_previously_changed?
      attrs[:vendor_id] = vendor_id if vendor_id_previously_changed?

      self.stock_products.find_each do |stock_product|
        stock_product.store_ids = store_ids.to_a
        stock_product.save
      end

      self.stock_products.update_all(attrs) unless attrs.blank?
    end

    # def ensure_vendor_base_currency
    #   unless self.vendor.present? && self.vendor.base_currency.present?
    #     errors.add("Unable to process as vendor's base currency not found")
    #     throw(:abort)
    #   end
    # end

  end
end

::Spree::Product.prepend(Spree::ProductDecorator) unless ::Spree::Product.ancestors.include?(Spree::ProductDecorator)
