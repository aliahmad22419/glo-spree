module Spree
  module LineItemDecorator
    def self.included(base)
      # include SharedMethods
      # base.include Exchangeable
      # base.include Spree::VatPriceCalculation
      base.enum send_gift_card_via: { sms: 0, email: 1, both: 2 }
      base.enum shipment_type: { shipment_default: 0, shipment_scheduled: 1 }
    end
    # serialize :customization_options, Array
    # Spree::PermittedAttributes.line_item_attributes.push *[:store_id, :message, customization_options: [:customization_option_id, :value]]
    # GIFT_CARD_TYPES = ['tsgift_digital','tsgift_physical', 'givex_digital', 'givex_physical'] unless const_defined?(:GIFT_CARD_TYPES)

    DIGITAL_TYPES = ["givex_digital", "blackhawk_digital", "tsgift_digital"] unless const_defined?(:DIGITAL_TYPES)

    PHYSICAL_TYPES = ["givex_physical", "blackhawk_physical", "tsgift_physical"] unless const_defined?(:PHYSICAL_TYPES)

    GIFTCARD_WITH_BOTH_TYPE = ["givex_both", "food_both", "blackhawk_both", "tsgift_both"] unless const_defined?(:GIFTCARD_WITH_BOTH_TYPE)

    FOOD_TYPES = ["food_pickup", "food_delivery"] unless const_defined?(:FOOD_TYPES)

    PRODUCT_TYPES = [:simple, :voucher, :givex_digital, :givex_physical,
      :food_pickup, :food_delivery, :tsgift_digital, :tsgift_physical]  unless const_defined?(:PRODUCT_TYPES)

    PRICE_FIELDS = [ :price, :cost_price, :adjustment_total, :additional_tax_total,
      :promo_total, :included_tax_total, :pre_tax_amount, :taxable_adjustment_total,
      :non_taxable_adjustment_total, :customizations_total, :sub_total, :amount] unless const_defined?(:PRICE_FIELDS)

    Spree::PermittedAttributes.line_item_attributes.push *[:store_id, :glo_api, :vendor_id, :message, :customization_options,
                                                           :receipient_email, :receipient_first_name, :receipient_last_name, :shipment_type,
                                                           :receipient_last_name, :receipient_phone_number, :delivery_mode, :message, :sender_name]

    def self.prepended(base)
      base.include Exchangeable
      base.include Spree::VatPriceCalculation
      base.attr_accessor :exchanged_prices, :is_edit_mode

      base.has_many :line_item_customizations, dependent: :destroy, class_name: "Spree::LineItemCustomization"
      base.has_one :line_item_exchange_rate, dependent: :destroy, class_name: "Spree::LineItemExchangeRate"
      base.belongs_to :store, class_name: 'Spree::Store'
      base.belongs_to :vendor, class_name: 'Spree::Vendor'
      base.has_many :ts_giftcards, dependent: :destroy, class_name: "Spree::TsGiftcard"
      base.has_many :givex_cards, dependent: :destroy, class_name: "Spree::GivexCard"
      base.has_one :sale_analysis, class_name: 'Spree::SaleAnalysis'
      base.has_many :email_changes, :as => :updatable
      base.has_one :calculated_price, as: :calculated_price, class_name: 'Spree::CalculatedPrice'
      base.has_one :fulfilment_info, class_name: 'Spree::FulfilmentInfo'
      base.accepts_nested_attributes_for :email_changes
      # validates :receipient_email, presence: true, allow_blank: false, allow_nil: false
      base.before_create :ensure_vendor_name
      base.before_save :add_delivery_charges_to_price, if: :will_save_change_to_price?

      delegate :stock_status, to: :product
      base.whitelisted_ransackable_associations = %w[product variant store]
      base.whitelisted_ransackable_attributes = %w[vendor_id variant_id created_at receipient_first_name receipient_last_name receipient_email receipient_phone_number]

      base.validates :price, :custom_price, :sub_total, numericality: { greater_than_or_equal_to: 0 }
      base.validate :custom_price_range_validation
      base.validate :receipient_email_format, if: -> { receipient_email.present? }

    end


    def self.created_at_gt_scope(date)
      where("created_at >= ?", DateTime.parse(date).beginning_of_day)
    end

    def self.created_at_lt_scope(date)
      where("created_at <= ?", DateTime.parse(date).end_of_day)
    end

    def self.ransackable_scopes(auth_object = nil)
      %i(created_at_gt_scope created_at_lt_scope)
    end

    def eligible_bonus_card_promo
      store = self.order.store
      return false if store.preferences[:enable_bonus_card_promo].blank?

      is_datetime = (DateTime.strptime(store.preferred_start_date, "%Y-%m-%dT%H:%M:%S%z") rescue false)
      completed_at, start_date, end_date = if is_datetime
          [order.completed_at, store.preferred_start_date.to_datetime, store.preferred_end_date.to_datetime]
        else
          [order.completed_at.to_date, store.preferred_start_date.to_date, store.preferred_end_date.to_date]
        end

      self.price_values(order.currency)[:sub_total].to_f >= store.preferences[:min_purchase] && completed_at.between?(start_date, end_date)
    end

    def ensure_vendor_name
      vendor = Spree::Vendor.find_by_id self.vendor_id

      if vendor.try(:name)
        self.vendor_name = vendor.name
      end
    end

    def refactor_customization new_customizations
      prev = self.line_item_customizations.map(&:customization_option_id)
      new_ones = new_customizations.map{|opt| opt[:customization_option_id]}

      removed_items = (prev - new_ones)
      removed_items = self.line_item_customizations.where(customization_option_id: removed_items)
      removed_items.destroy_all
    end

    def options=(options = {})
      return unless options.present?
      customizations = options[:customization_options]
      opts = options.dup # we will be deleting from the hash, so leave the caller's copy intact
      currency = opts.delete(:currency) || order.try(:currency)
      opts.delete(:customization_options)
      self.vendor_id = product.vendor_id
      self.local_area_delivery = product.local_area_delivery
      self.wide_area_delivery = product.wide_area_delivery
      self.product_type = product.product_type
      self.delivery_mode = (product.product_type == 'simple') || (product.product_type == 'voucher')?  product.product_type : product.delivery_mode
      self.send_gift_card_via = product.send_gift_card_via
      self.shipping_category = product.shipping_category.name
      update_price_from_modifier(currency, opts)
      assign_attributes opts
      self.update_customizations customizations
    end

    def update_customizations customizations
      if customizations.blank?
        self.line_item_customizations.destroy_all
        self.calculate_sub_total []
      end
      return unless customizations.present?
      refactor_customization customizations
      updated_customizations = []
      customizations.each do |cust_hash|
        updated_customizations << customize_line_item(cust_hash)
      end
      self.calculate_sub_total updated_customizations.compact
    end

    def customize_line_item options
      cust_opt = Spree::CustomizationOption.find_by_id options[:customization_option_id]
      return if cust_opt.blank?
      cust_obj = self.line_item_customizations.find_or_initialize_by(customization_option_id: options[:customization_option_id])
      customization = cust_opt.customization
      cust_obj.customization_id = customization.id
      cust_obj.name = customization.label
      cust_obj.field_type = customization.field_type
      cust_obj.price = cust_opt.price.to_f
      cust_obj.title = cust_opt.label
      cust_obj.value = options[:value]
      cust_obj.sku = cust_opt.sku

      gift_options = (options[:gift] || {})
      if gift_options[:user_gift_amount].present?
        self.custom_price = gift_options[:user_gift_amount].to_f
        self.price = 0
      end
      self.save

      if customization.field_type == "File"
        cust_obj.save_image options[:value]
      elsif customization.field_type == "Color"
        cust_obj.value = cust_opt.color_code
      end
      self.is_gift_card = product.product_is_gift_card
      cust_obj.save!
      cust_obj
    end

    # TODO also use exchangeable module
    def update_exchange_rates
      to_currency = self.currency
      from_currency = product.vendor.try(:base_currency)

      if from_currency.present?
        client = self.order.store.client
        curr = client&.currencies.with_out_vendor_currencies.find_by_name from_currency.name
        current_exchange_rate = (curr.present? ? curr.exchange_rates.where(name: to_currency)[0].try(:value) : 1)
        markup = from_currency.markups.where(name: to_currency)[0].try(:value)

        exchange = Spree::LineItemExchangeRate.find_or_initialize_by(line_item_id: self.id)
        exchange.to_currency = to_currency
        exchange.from_currency = from_currency.name
        exchange.mark_up = (markup || 0)
        exchange.exchange_rate = (current_exchange_rate || 1)
        exchange_rate_value = exchange.exchange_rate
        exchange_rate_value += (exchange_rate_value * exchange.mark_up/100) if exchange.mark_up != 0 && exchange.mark_up.present?
        exchange.save!
        #save updated exchange in line_item
        self.item_exchange_rate = exchange_rate_value
        self.save!
      end
    end

    def shipping_method_name
      self.order.shipments.select{ |shipment| shipment.line_items.compact.map(&:id).include? (self.id) }.first&.shipping_method&.name
    end

    def calculate_sub_total with_customizations
      customizations_price = with_customizations.sum(&:price)
      self.sub_total = self.price + customizations_price + self.custom_price
      self.customizations_total = customizations_price
      if self.persisted?
        self.save!
        order.update_with_updater!
      end
    end

    def add_delivery_charges_to_price
      update_price
      self.sub_total = price + customizations_total + self.custom_price
    end

    def amount
      sub_total * quantity
    end

    def update_price
      # self.price = variant.price_including_vat_for(tax_zone: tax_zone)
      return nil if self.order.single_page_order?
      self.price = if self.custom_price.zero?
        (product.on_sale? ? product.price_with_delivery_charges(order.store) : variant.price_with_delivery_charges(order.store))
      else 0 end
    end

    def price_values to_currency=currency, from_currency=nil
      self.exchanged_prices = PRICE_FIELDS.inject({}){ |hash,(key,value)| hash.merge({ key => tp(exchanged(key, to_currency, from_currency), to_currency) }) }
      unless self.custom_price.zero?
        self.exchanged_prices[:sub_total] = tp(float_tp(self.exchanged_prices[:customizations_total], to_currency) + self.custom_price + self.price, to_currency)
        self.exchanged_prices[:amount] = tp(quantity * float_tp(self.exchanged_prices[:sub_total], to_currency), to_currency)
      end
      self.exchanged_prices.merge!({splitted_taxes: splitted_taxes(to_currency), item_tax: tp(float_tp(self.exchanged_prices[:additional_tax_total]) / quantity, to_currency) })
      self.exchanged_prices
    end

    def price_values_for_report to_currency=currency, from_currency=nil
      self.exchanged_prices = PRICE_FIELDS.inject({}){ |hash,(key,value)| hash.merge({ key => tp(exchanged(key, to_currency, from_currency, true), to_currency) }) }
      self.exchanged_prices.merge!({splitted_taxes: splitted_taxes(to_currency), item_tax: tp(float_tp(self.exchanged_prices[:additional_tax_total]) / quantity, to_currency) })
      self.exchanged_prices
    end

    def saved_exchange_rate
      rate = self.line_item_exchange_rate
      exchange_rate_value = rate&.exchange_rate
      mark_up_value = rate&.mark_up
      exchange_rate_value += (exchange_rate_value * mark_up_value/100) if mark_up_value != 0 && mark_up_value.present?
      (exchange_rate_value || 1)
    end

    def self.to_csv(user = nil, q)
      vendor_dashboard_attributes = ["Product Name","Vendor Name", "Storefront", "Sku", "Variant Options","No. of Sales", "Total"]

      CSV.generate(headers: true) do |csv|
        if user.present? && (user.spree_roles.map(&:name).include?"vendor")
          vendor = user.vendors.first
          vendor_base_currency = vendor&.base_currency&.name
          products = vendor.line_items.ransack(q).result
        else
          vendor_base_currency = "USD"
          q[:vendor_id_in] = user&.client&.vendor_ids
          products = Spree::LineItem.ransack(q).result
        end
        products = products.select("SUM(spree_line_items.quantity) as total_qty, SUM(spree_line_items.sub_total * spree_line_items.quantity) as final_total,
                                    spree_line_items.store_id, spree_line_items.variant_id, spree_line_items.vendor_name")
                           .joins("INNER JOIN spree_orders ON spree_orders.id = spree_line_items.order_id")
                           .where("spree_orders.state = 'complete'")
                           .group("spree_line_items.variant_id, spree_line_items.store_id, spree_line_items.vendor_name")
        currency_sysmbol = Spree::Money.new(vendor_base_currency).currency.symbol
        csv << vendor_dashboard_attributes
        products.each do |p|
          next if p.variant.blank? || p.product.blank?
          csv_line = []
          csv_line << p.name
          csv_line << p&.vendor_name
          csv_line << p&.store&.name
          csv_line << p.sku
          csv_line << p.variant.options_text
          csv_line << p.total_qty
          csv_line << currency_sysmbol + p.final_total.to_s
          csv << csv_line
        end
      end
    end

    def splitted_taxes to_currency=currency, taxes=adjustments.tax
      details = {}
      details[:included] = taxes.is_included.map{ |tax| exchanged_adjustment_label(tax, to_currency) }
      details[:additional] = taxes.additional.map{ |tax| exchanged_adjustment_label(tax, to_currency) }
      details
    end

    def sufficient_stock?
      Spree::Stock::Quantifier.new(variant).can_supply? order.line_items.where(variant: variant).sum(&:quantity) # quantity
    end

    def total_tax type
      line_tax = order.lineitem_related([self]).send("#{type.to_s}_tax")
      ship_tax = order.shipment_related(order.shipments.where(line_item_id: id)).send("#{type.to_s}_tax")
      (line_tax + ship_tax)
    end

    def total_tax_without_shipment type
      return order.lineitem_related([self]).send("#{type.to_s}_tax")
    end

    def voucher_image_url
      image_url = ''
      store = order&.store
      if product&.voucher_email_image == "generic_image"
        image_url = store&.email_thumbnail
      else
        image_url = variant&.email_thumbnail || product&.email_thumbnail
      end
      image_url
    end

    def generate_givex_card givex_card_id, generate_bonus_card = false
      givex_card = Spree::GivexCard.find givex_card_id
      prices = price_values(order.currency)
      first_name = receipient_first_name
      last_name = receipient_last_name
      phone_number = receipient_phone_number
      email = receipient_email
      if generate_bonus_card
        bonus_price = prices[:sub_total].to_f * store.preferences[:bonus_percentage] / 100
        billing_address = order&.billing_address
        first_name = billing_address&.firstname
        last_name = billing_address&.lastname
        phone_number = self.receipient_phone_number.present? ? billing_address&.phone : nil
        email = order.email
      end
      options = { id: id.to_s + givex_card_id.to_s, amount: generate_bonus_card ? bonus_price : prices[:sub_total], store_id: order.store.id, comments: order&.number}
      result = Spree::RegisterGivex.call(options: options)
      givex_card.update({givex_response: result.to_json, transaction_code: self.id,customer_email: email,
                                        customer_first_name: first_name, customer_last_name: last_name, receipient_phone_number: phone_number,
                                        user_id: order&.user&.id, line_item_id: self.id, order_id: order.id, store_id: store.id,
                                        send_gift_card_via: (product&.send_gift_card_via || "email"),client_id: order&.store&.client&.id})

      if result && result.value["result"].count > 5
        response = result.value
        expiry_date = Date.parse(response["result"][5]) unless response["result"][5] == "None"
        givex_card.givex_number = response["result"][3]
        givex_card.givex_transaction_reference = response["result"][2]
        givex_card.balance = response["result"][4]
        givex_card.expiry_date = expiry_date
        givex_card.receipt_message =  response["result"][6]
        givex_card.comments =  response["result"][7]
        givex_card.card_generated = true
        ApplePass.new(givex_card).send(:attach) if givex_card.save
        givex_card.check_balance(order.store.id)
        if product&.send_gift_card_via&.eql?("both") || product&.send_gift_card_via&.eql?("email")
          if order&.store&.ses_emails
            SesEmailsDataWorker.perform_async(givex_card.id, "digital_givex_card_recipient")
          else
            Spree::GeneralMailer.send_givex_cadentials_to_customer(givex_card).deliver_now
          end
        end
        if (self&.product&.send_gift_card_via&.eql?("sms") || self&.product&.send_gift_card_via&.eql?("both")) && self&.receipient_phone_number&.present?
          SmsWorker.perform_async(order.store.id, givex_card.receipient_phone_number, "Spree::GivexCard", givex_card.slug)
        end
      end
    end

    def gift_card_number
      client = order&.store&.client
      card_numbers = if delivery_mode == 'givex_digital' || delivery_mode == 'givex_physical'
          givex_cards.map{|givex|
            givex.is_gift_card_number_display(givex.givex_number,client)
          }
      elsif delivery_mode == 'tsgift_digital' || delivery_mode == 'tsgift_physical'
          ts_giftcards.map{|tsCard|
            tsCard.is_gift_card_number_display(tsCard.number,client)
          }
      elsif is_gift_card
        Spree::GiftCard.where(line_item_id: id).map(&:code)
      end
      card_numbers&.reject(&:blank?)&.join(", ")
    end

    def gift_card_iso_number
      ios_number = if store&.preferred_single_page
        [line_item_customizations.find_by_name("Serial Number")&.value]
      elsif delivery_mode == 'givex_digital' || delivery_mode == 'givex_physical'
        givex_cards.map(&:iso_code)
      elsif delivery_mode == 'tsgift_digital' || delivery_mode == 'tsgift_physical'
        ts_giftcards.map(&:serial_number)
      end
      ios_number&.reject(&:blank?)&.join(", ")
    end

    def gift_card_number_for_google_sheet
      card_numbers = if delivery_mode == 'givex_digital' || delivery_mode == 'givex_physical'
                     givex_cards.map(&:givex_number)
                   elsif delivery_mode == 'tsgift_digital' || delivery_mode == 'tsgift_physical'
                     ts_giftcards.map(&:number)
                   end
      card_numbers&.reject(&:blank?)&.join(", ")
    end
    def gift_card_serial_number_without_bouns
      card_numbers =  if delivery_mode == 'givex_digital' || delivery_mode == 'givex_physical'
                        givex_cards.where(bonus: false).map(&:iso_code)
                      elsif delivery_mode == 'tsgift_digital' || delivery_mode == 'tsgift_physical'
                        ts_giftcards.where(bonus: false).map(&:serial_number)
                      end
      card_numbers&.reject(&:blank?)
    end

    def generate_csv_data(order, item_shipmnent, shipment_state, payment_method, promo_code, customer_name, enabled_marketing)
      voucher_recipent_name = self&.line_item_customizations&.where(name: 'Gift Card Name')&.first&.try(:value)
      data = []
      data << order.number
      data << order&.store&.name
      data << self&.product&.vendor&.name
      data << "UTC"
      data << Spree::Order.local_date(order.completed_at)&.strftime("%B %d, %Y")
      data << Spree::Order.local_date(order.completed_at)&.strftime("%I:%M %p")
      data << order.state
      data << customer_name
      data << order.ship_address&.LineItem&.name
      data << self&.variant&.name
      data << self&.variant&.sku
      data << self.product.vendor_sku
      data << self&.options_text
      data << self&.quantity
      data << self.exchanged_prices[:sub_total]
      data << item_shipmnent&.delivery_pickup_date&.strftime("%B %d, %Y")
      data << item_shipmnent&.delivery_pickup_time
      data << Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%B %d, %Y")
      data << Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%I:%M %p")
      data << self.line_item_exchange_rate&.to_currency
      data << self.line_item_exchange_rate&.from_currency
      data << self.line_item_exchange_rate&.exchange_rate
      data << self.exchanged_prices[:amount]
      data << "%.2f" % self.total_tax(:included)
      data << "%.2f" % self.total_tax(:additional)
      data << "%.2f" % (order.exchanged_prices[:vendor_based_shipment][self.vendor_id].to_f)
      data << order.exchanged_prices[:ship_total]
      data << order.exchanged_prices[:promo_total]
      data << order.exchanged_prices[:total]
      data << promo_code
      data << payment_method
      data << self.shipping_method_name
      data << shipment_state
      data << order&.order_tags&.pluck('label_name')&.join(',')
      data << self.delivery_mode
      data << (self.is_gift_card? ? voucher_recipent_name : "#{self.receipient_first_name} #{self.receipient_last_name}")
      data << enabled_marketing
      data << self&.product&.tag_list&.first
      data
    end

    def ses_email_data
      line_items = []
      line_item_data = {}
      line_item_data[:name] = "#{self.product.vendor.name.upcase} : #{self.variant.product.name.upcase}"
      line_item_data[:vendor_name] = self.product.vendor.name
      line_item_data[:product_name] = self.variant.product.name
      line_item_data[:terms_and_conditions] = self.variant.product&.preferred_terms_and_conditions
      line_item_data[:quantity] = self.quantity
      line_item_data[:digital] = DIGITAL_TYPES.include?self.delivery_mode
      line_item_data[:physical] = PHYSICAL_TYPES.include?self.delivery_mode

      line_item_data[:option_values] = []
      self.variant&.option_values&.each do |var_opt|
        line_item_data[:option_values].push({ key: var_opt.option_type&.name, value: var_opt.name })
      end

      line_item_data[:customizations] = []
      customizations = self.line_item_customizations.joins(:customization).order("spree_customizations.order, spree_customizations.updated_at ASC")
      customizations.each do |personalization|
        line_item_data[:customizations].push({ key: personalization.name, value: personalization.text })
      end
      line_items.push(line_item_data)
    end

    def error_log_product_details
      customizations = product.customizations&.pluck(:label)&.join(', ')
      [
        "Product SKU: #{product.sku}",
        "Product Type: #{product.product_type.titleize} (#{delivery_mode.titleize})",
        "Product URL: https://#{store.url}/#{product.slug}",
        "Tax Category: #{product.tax_category&.name&.titleize || 'N/A'}",
        "Shipping Category: #{product.shipping_category&.name&.titleize || 'N/A'}",
        "Payment Method: #{order.payments.completed.map(&:payment_method).pluck(:name).join(', ')}",
        "Customizations: #{customizations.present? ? customizations : 'N/A'}",
        "Options: #{option_values_text.present? ? option_values_text.map(&:values).flatten: 'N/A'}\n"
      ].compact.join("\n")
    end

    private

    def custom_price_range_validation
      return unless store.preferred_enable_customization_price
      return if custom_price.blank? || custom_price.zero?

      min_price, max_price = store.min_custom_price.to_f, store.max_custom_price.to_f
      errors.add(:custom_price, "must be between #{min_price} and #{max_price}") unless custom_price.in? min_price..max_price
    end

    def receipient_email_format
      errors.add(:base, "Recipient email is invalid") and return unless receipient_email.match?(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i)
    end

    def send_associated_emails
      self.givex_cards.is_generated.where(bonus: false).each do |gift_card|
        SesEmailsDataWorker.perform_async(gift_card.id, "digital_givex_card_recipient")
      end
      self.ts_giftcards.is_generated.where(bonus: false).each do |gift_card|
        SesEmailsDataWorker.perform_async(gift_card.id, "digital_ts_card_recipient")
      end
    end
  end
end

::Spree::LineItem.prepend(Spree::LineItemDecorator) unless ::Spree::LineItem.ancestors.include?(Spree::LineItemDecorator)
