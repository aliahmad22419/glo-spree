module Spree
  module OrderDecorator

    CRYPTO_SOURCE_ATTRIBUTES = [:crypto_amount, :crypto_currency, :track_id, :customer_id, :source_name, :status] unless const_defined?(:CRYPTO_SOURCE_ATTRIBUTES)
    Spree::PermittedAttributes.source_attributes.push *[:utm_nooverride, :payer_id, :order_id, :transaction_id]
    Spree::PermittedAttributes.source_attributes.push *CRYPTO_SOURCE_ATTRIBUTES
    Spree::PermittedAttributes.checkout_attributes.push *[:pick_up_date, :pick_up_time, :delivery_type, :customer_comment, :customer_first_name, :customer_last_name, :enabled_marketing, :news_letter]

    def self.prepended(base)
      base.prepend AASM
      base.include Exchangeable
      base.include PriceValues
      base.prepend PaymentSplits
      base.extend  Archive
      base.prepend Spree::Webhooks::HasWebhooks

      base.preference :single_page, :boolean, default: false
      base.preference :currency_formatter, :boolean, default: false
      base.preference :decimal_points, :integer, default: 2
      base.preference :stripe_connected_account, :string, default: nil

      base.has_many :questions, as: :questionable, class_name: 'Spree::Question'
      base.has_many :givex_cards, dependent: :destroy, :class_name => 'Spree::GivexCard'
      base.has_many :hawk_cards, dependent: :destroy, :class_name => 'Spree::HawkCard'
      base.has_many :ts_giftcards, dependent: :destroy, :class_name => 'Spree::TsGiftcard'
      base.has_and_belongs_to_many :order_tags, class_name: 'Spree::OrderTag'
      base.has_many :sale_analyses, class_name: 'Spree::SaleAnalysis'
      base.has_many :payment_intents, as: :intentable
      base.has_many :error_logs, class_name: 'Logs::OrderErrorLog', dependent: :destroy
      base.has_one :calculated_price, as: :calculated_price, class_name: 'Spree::CalculatedPrice'
      base.belongs_to :zone, class_name: 'Spree::Zone'
      base.belongs_to :bulk_order, class_name: 'Spree::BulkOrder', optional: true

      base.scope :fulfilment_store_orders, -> {  joins(:store).where('spree_orders.completed_at >= spree_stores.fulfilment_start_date AND spree_orders.store_id = spree_stores.id AND spree_stores.allow_fulfilment = ?', true)}
      base.after_commit :homogenize_bulk_order, if: :saved_change_to_state?
      base.before_save :homogenize_line_item_currencies, if: :currency_changed?
      base.after_create :update_number_prefix_suffix
      base.enum ts_action: { ts_not_required: 0, ts_required: 1, ts_fullfilled: 2 }
      base.enum error_log_status: [:initiated, :failed, :resolved, :unresolved]

      base.whitelisted_ransackable_associations = %w[ zone created_by shipments user promotions bill_address ship_address line_items store payments]
      base.whitelisted_ransackable_attributes = %w[ completed_at email number shipments_card_generation_datetime_not_null shipments_state_cont state payment_state shipment_state total considered_risky channel status created_at completed_at number spo_invoice]
    end

    def homogenize_line_item_currencies
      line_items.each {
        |li|
        li.currency = self.currency
        li.save
      }
    end

    def self.completed_at_gt_scope(date)
      where("completed_at >= ?", DateTime.parse(date).beginning_of_day)
    end

    def self.completed_at_lt_scope(date)
      where("completed_at <= ?", DateTime.parse(date).end_of_day)
    end

    def self.completed_at_gt_time_scope(datetime)
      where("completed_at >= ?", DateTime.parse(datetime))
    end

    def self.completed_at_date_scope(date)
      where(completed_at: DateTime.parse(date).beginning_of_day..DateTime.parse(date).end_of_day)
    end

    def self.status_scope(status)
      if status == 'shipped'
        where(shipment_state: 'shipped')
      else
        where.not(shipment_state: 'shipped')
      end
    end

    def self.ransackable_scopes(auth_object = nil)
      %i(completed_at_date_scope completed_at_gt_scope completed_at_lt_scope status_scope completed_at_gt_time_scope)
    end

    def paid?
      payment_state == 'paid' || payment_state == 'credit_owed'
    end

    def in_finalized_state?
      self.complete? || self.returned? || self.awaiting_return?
    end

    def generate_cart_token
      update_column(:cart_token, get_new_cart_token)
    end

    def delivery_required?
      true
    end

    def update_sale_analyses
      self.sale_analyses.update(tags:  self&.order_tags&.pluck('label_name')&.join(',')) if self.sale_analyses.present?
    end

    def update_from_params(params, permitted_params, request_env = {})
      success = false
      @updating_params = params
      run_callbacks :updating_from_params do

        # Set existing card after setting permitted parameters because
        # rails would slice parameters containg ruby objects, apparently
        existing_card_id = @updating_params[:order] ? @updating_params[:order].delete(:existing_card) : nil

        attributes = @updating_params[:order] ? @updating_params[:order].permit(permitted_params).delete_if { |_k, v| v.nil? } : {}
        payment_attributes = attributes[:payments_attributes].first if attributes[:payments_attributes].present?

        if existing_card_id.present?
          credit_card = Spree::CreditCard.find existing_card_id
          if credit_card.user_id != user_id || credit_card.user_id.blank?
            raise Spree::Core::GatewayError, Spree.t(:invalid_credit_card)
          end

          credit_card.verification_value = params[:cvc_confirm] if params[:cvc_confirm].present?

          attributes[:payments_attributes].first[:source] = credit_card
          attributes[:payments_attributes].first[:payment_method_id] = credit_card.payment_method_id
          attributes[:payments_attributes].first.delete :source_attributes
        end

        if payment_attributes.present?
          payment_attributes[:request_env] = request_env
          source = params[:order][:payments_attributes][0] rescue {}

          payment_attributes[:source] = if (token = payment_attributes[:braintree_token]).present?
            Spree::BraintreeCheckout.create_from_token(token, payment_attributes[:payment_method_id])
          elsif payment_attributes[:braintree_nonce].present?
            Spree::BraintreeCheckout.create_from_params(params)
          elsif source[:paypal].present?
            paypal_method = store.payment_methods.active.find_by_type('Spree::Gateway::PayPalExpress')
            attributes[:payments_attributes][0][:payment_method_id] = paypal_method.try(:id)
            attributes[:payments_attributes][0][:state] = "checkout"
            Spree::PaypalExpressCheckout.create({
              payer_id: source[:payer_id],
              transaction_id: source[:transaction_id],
              order_id: source[:order_id],
              })
          elsif source[:link_payment].present?
            Spree::LinkSource.create({
              payment_method_id: payment_attributes[:payment_method_id],
              state: :initialized
            })
          end
        end
        if attributes[:payments_attributes].present? and attributes[:payments_attributes][0][:amount].blank?
          attributes[:payments_attributes][0].merge!(amount: order_total_after_store_credit)
        end
        if attributes[:payments_attributes].present? and attributes[:payments_attributes][0][:amount].present? and paid_partially
          attributes[:payments_attributes][0].merge!(amount: price_values[:prices][:payable_amount])
        end
        success = update(attributes)
        set_shipments_cost if shipments.any?
      end

      @updating_params = nil
      success
    end

    def payment_method_type
      payments.completed.last&.payment_method&.type
    end

    def inclusive_payment_methods_types
      payments&.map(&:payment_method)&.pluck(:type) || []
    end

    def payment_through_adyen?
      payments.pending.last&.payment_method&.type&.eql?("Spree::Gateway::AdyenGateway")
    end

    def process_payments_with(method)
      order_total = BigDecimal(price_values[:prices][:total])
      return if payment_total >= order_total
      raise Spree::Core::GatewayError.new(Spree.t(:no_payment_found)) if unprocessed_payments.empty? #&& wallet_payments.empty?

      [unprocessed_payments].flatten.each do |payment|
        break if payment_total >= order_total

        payment.public_send(method)

        if payment.completed?
          self.payment_total += payment.amount
        end
      end
    rescue Spree::Core::GatewayError => e
      result = !!Spree::Config[:allow_checkout_on_gateway_error]
      self.send(:cancel_stripe_payment)
      errors.add(:base, e.message) and return result
    end

    def update_params_payment_source
      if @updating_params[:payment_source].present?
        source_params = @updating_params.
                        delete(:payment_source)[@updating_params[:order][:payments_attributes].
                        first[:payment_method_id].to_s]

        if source_params
          @updating_params[:order][:payments_attributes].first[:source_attributes] = source_params
        end
      end

      if @updating_params[:order] && (@updating_params[:order][:payments_attributes] ||
                                      @updating_params[:order][:existing_card])
        @updating_params[:order][:payments_attributes] ||= [{}]
        @updating_params[:order][:payments_attributes].first[:amount] = BigDecimal(price_values[:prices][:payable_amount])
      end
    end

    def reset_order_state
      self.remove_gift_card_payments
      if self.paid_partially
        self.payments.gift_cards.completed.each { |payment| payment.source.credit(payment.amount, payment.response_code)}
        self.payments.giftcard_invalidateable.update_all(state: 'invalid')
        self.payments.gift_cards.where(state: 'invalid').destroy_all
        self.update(paid_partially: false)
      end
      unless self.confirm? && self.payments.completed.any?
        Spree::Order.transaction do
          self.reload
          unless self.cart?
            Spree::Cart::Update.call(order: self, params: {})
            self.ship_address = self.bill_address = nil
            Spree::TaxRate.adjust(self, self.line_items)
            self.payments.pending.each(&:failure)
          end
        end
        self.promotions.find_each do |promotion|
          if promotion.code.present? || promotion.actions.detect{ |act| act.type.eql?('Spree::Promotion::Actions::BinCodeDiscount')}.present?
            self.order_promotions.find_by!('spree_order_promotions.promotion_id = ?', promotion.id).destroy
            promotion_handler.send(:remove_promotion_adjustments, promotion)
            promotion_handler.send(:remove_promotion_line_items, promotion)
            self.update_with_updater!
          end
        end

        order_state = store.checkout_v3? && self.digital? && !store.enable_v3_billing? ? 'address' : 'cart'
        self.update_columns(state:  order_state, updated_at: Time.current)
      end
    end

    def promotion_handler
      Spree::PromotionHandler::Coupon.new(self)
    end

    def outstanding_balance
      order_prices = self.price_values[:prices]
      total_paid = float_tp(payments.completed.includes(:refunds).inject(0) { |sum, payment| sum + payment.amount - payment.refunds.sum(:amount) })

      outstanding_amount = if canceled?
        -1 * total_paid
      elsif refunds.exists?
        # If refund has happened add it back to total to prevent balance_due payment state
        # See: https://github.com/spree/spree/issues/6229 & https://github.com/spree/spree/issues/8136
        float_tp(order_prices[:total]) - (total_paid + float_tp(refunds.sum(:amount)))
      else
        (last_payment_is.eql?("partial") ? order_prices[:payable_amount] : (float_tp(order_prices[:total]) - total_paid))
      end

      self.float_tp(outstanding_amount)
    end

    def save_line_item_exchange_rates
      self.line_items.each do |item|
        item.update_exchange_rates
        item.variant&.option_values&.each do |option_value|
          item.option_values_text.push({value: "#{option_value.option_type&.name} : #{option_value.presentation}"})
        end
        item.save
      end

      # set order preferences
      self.send(:set_completion_config)
    end

    def increase_client_order_id
      last_order_id = self&.store&.orders&.complete&.order("client_order_id ASC")&.last&.client_order_id || 0
      self.client_order_id = last_order_id + 1
      self.save
    end

    def ensure_non_zero_cart
      return true if last_payment_is.eql?("partial")

      unless float_tp(price_values[:prices][:payable_amount]).positive?
        errors.add(:base, Spree.t(:zero_cart_error))
        false
      else
        true
      end
    end

    def ensure_payments_via_gift_card_are_captured
      payments.checkout.each(&:process!)
      true
    end

    def delete_cache_after_checkout
      store&.clear_store_cache()
    end

    def generate_gift_cards
      line_items_digital = line_items.where(is_gift_card: true).includes(:line_item_customizations)
      line_items_digital.each do |line_digital|
        email_for_gift_card = line_digital.line_item_customizations.where(name: 'Gift Card Email').first
        name_for_gift_card = line_digital.line_item_customizations.where(name: 'Gift Card Name').first
        gift_card = line_digital.line_item_customizations.where(name: 'Select gift card value').first
        exchange_rate_for_voucher= line_digital.apply_exchange_rate(currency)
        if email_for_gift_card.present? && name_for_gift_card.present?
          line_digital.quantity.times do
            gift_card_price = float_tp(((line_digital.sub_total-((line_digital.included_tax_total.to_f)/line_digital.quantity)))*exchange_rate_for_voucher, currency)
            Spree::GiftCard.create(name: name_for_gift_card.value, email: email_for_gift_card.value, enabled: true,
                                  variant_id: line_digital.variant.id, current_value: gift_card_price,
                                  original_value: gift_card_price, line_item_id: line_digital.id,
                                  client_id: store.client_id, currency: currency)
          end
        end
      end
    end

    def generate_ts_cards
      self.shipments.gift_card_shipments.each do |shipment|
        next if shipment.shipping_method.scheduled_fulfilled
        GenerateTsCardsWorker.perform_async(shipment.id) unless self.single_page_order?
        FullfillDigitalShipmentWorker.perform_in(3.minutes, shipment.id) if DIGITAL_TYPES.include?(shipment.delivery_mode)
      end
      AutoBookLalamoveWorker.perform_async(id)
    end

    def generate_hawk_cards
      # line_items_digital = line_items.where(delivery_mode: 'blackhawk_digital', delivery_mode: 'blackhawk_physical')
      line_items_digital = line_items.where(delivery_mode: ['blackhawk_digital', 'blackhawk_physical'])

      line_items_digital.each do |line_digital|
        store_cards_arr = []
        line_digital.quantity.times do
          store_card_hash = {
            "Sku": "CPL001",
            "DisplayName": line_digital.receipient_first_name,
            "DisplayMessage": "Gift Card",
            "DeliveryEmail": line_digital.receipient_email,
            "CardValue": line_digital.price.to_s
          }
          store_cards_arr.push(store_card_hash)
        end

        options = { customer_email: line_digital&.receipient_email, customer_first_name: line_digital&.receipient_first_name, store_cards_arr: store_cards_arr, store_id: store.id, order_id: line_digital.order.id, delivery_mode: line_digital&.delivery_mode }
        result = Spree::RegisterHawk.call(options: options)

        if result.value["Result"] == 0
          store_cards = result.value["Response"]["StoreCards"]
          store_cards.each do |store_card|
            hawk_card = Spree::HawkCard.new(hawk_response: result.to_json, transaction_code: line_digital.id,
                                            customer_first_name: line_digital.receipient_first_name, customer_last_name: line_digital.receipient_last_name,
                                            user_id: user&.id, line_item_id: line_digital.id, order_id: id)
            hawk_card.transaction_code = result.value["Response"]["TransactionCode"]
            hawk_card.bar_code_number = store_card["Barcode"]
            hawk_card.balance = store_card["CardValue"]
            hawk_card.expiry_date = store_card["ExpiryDate"]
            hawk_card.pin = store_card["Pin"]
            hawk_card.supplier_reference_no = store_card["SupplierReferenceNo"]
            hawk_card.url = store_card["Url"]
            hawk_card.sku = store_card["Sku"]
            hawk_card.delivery_email = store_card["DeliveryEmail"]
            hawk_card.card_type = store_card["CardType"]
            hawk_card.save
          end
        else
            hawk_card = Spree::HawkCard.new(hawk_response: result.to_json, transaction_code: line_digital.id,
                                            customer_first_name: line_digital.receipient_first_name, customer_last_name: line_digital.receipient_last_name,
                                            user_id: user&.id, line_item_id: line_digital.id, order_id: id)
            hawk_card.save
        end
      end
    end

    def send_data_to_sqs
      DashboardReportingWorker.perform_in(3.minutes, self.id)
    end

    def csv_details
      CSV.generate(headers: true) do |csv|
        csv << ["Name", "Description", "Option Types: Values", "Images"]

        self.line_items.each do |line_item|
          next if line_item.variant.blank? || line_item.product.blank?
          item = line_item.variant

          csv_line = []
          csv_line << item.product.name
          csv_line << Nokogiri::HTML(item.product.description).text
          csv_line << item.options_text
          csv_line << item.product.images.map{ |img| img.active_storge_url(img.attachment) }.join("\n")
          csv << csv_line
        end
      end
    end

    def self.local_date(date, timezone = 'UTC')
      date.present? ? date.in_time_zone(timezone) : nil
    end

    def self.to_csv(user, q = {})

      vendor_dashboard_headers = ["Order number", "Storefront", "Timezone", "Date Placed", "Status", "Customer", "Currency", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Tax(inclusive)", "Tax(exclusive)", "Tags", "Total"]
      headers = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Time Placed", "Order Status", "Customer Full Name", "Customer Address", "Customer First Name",  "Customer Last Name", "Shipping Delivery Country", "Customer Phone", "Customer Email", "Product name", "Product Sku", "Vendor Sku", "Variant", "Product quantity", "Product price", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Order currency", "Vendor Currency", "Exchange Rate", "Sub Total", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount amount", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Number", "Special Message", "Card Type", "Recipient Name", "Recipients First Name", "Recipients Last Name" ,"Recipient Email", "Recipient Phone Number", "Marketing Enabled", "Product Tag"]

      password = ''
      reports_path = "public/user-reports"
      Dir.mkdir("#{reports_path}") unless Dir.exist?("#{reports_path}")
      FileUtils.rm_rf(Dir["#{reports_path}/*"])

      filename = "orders-report-#{Date.today}.csv"
      file_path = "#{reports_path}/#{filename}"

      CSV.open("#{file_path}.csv", "wb") do |csv|
        if user.spree_roles.map(&:name).include?"vendor"
          vendor = user&.vendors&.first
          password = vendor&.sales_report_password
          q["email_cont"] = q.delete "email_or_user_email_cont"
          q = vendor.vendor_sale_analyses.ransack(q)
          orders = q.result(distinct: true).order("completed_at DESC")
          csv << vendor_dashboard_headers
          orders.each do |order|
            csv_line = []
            csv_line << order&.number
            csv_line << order&.storefront
            csv_line << "UTC"
            csv_line << order&.completed_at&.strftime("%B %d, %Y")
            csv_line << order&.status
            csv_line << order&.email
            csv_line << order&.currency
            csv_line << order&.delivery_pickup_date
            csv_line << order&.delivery_pickup_time
            csv_line << order&.shipped_date
            csv_line << order&.shipped_time
            csv_line << order&.tax_inclusive
            csv_line << order&.additional_tax
            csv_line << order&.tags
            csv_line << order&.total
            csv << csv_line
          end
        else
          q[:shipments_vendor_id_in] = user&.client&.vendor_ids
          password = user&.client&.sales_report_password
          q = Spree::Order.complete.ransack(q)
          orders = q.result(distinct: true).order("completed_at DESC")
          csv << headers
          orders.each do |order|
            order.line_items.each do |line_item|
              next if line_item.variant.blank? || line_item.product.blank?
              sale_analysis = line_item.sale_analysis
              csv_line = []
              csv_line << sale_analysis&.order_number
              csv_line << sale_analysis&.storefront
              csv_line << sale_analysis&.vendor
              csv_line << "UTC"
              csv_line << sale_analysis&.date_placed&.strftime("%B %d, %Y")
              csv_line << sale_analysis&.time_placed&.strftime("%I:%M %p")
              csv_line << sale_analysis&.order_status
              csv_line << sale_analysis&.customer_full_name
              csv_line << sale_analysis&.customer_address
              csv_line << sale_analysis&.customer_first_name
              csv_line << sale_analysis&.customer_last_name
              csv_line << sale_analysis&.shipping_delivery_country
              csv_line << sale_analysis&.customer_phone
              csv_line << sale_analysis&.customer_email
              csv_line << sale_analysis&.product_name
              csv_line << sale_analysis&.product_sku
              csv_line << sale_analysis&.vendor_sku
              csv_line << sale_analysis&.variant
              csv_line << sale_analysis&.product_quantity
              csv_line << sale_analysis&.product_price
              csv_line << sale_analysis&.delivery_pickup_date&.strftime("%B %d, %Y")
              csv_line << sale_analysis&.delivery_pickup_time
              csv_line << sale_analysis&.shipped_date&.strftime("%B %d, %Y")
              csv_line << sale_analysis&.shipped_time
              csv_line << sale_analysis&.order_currency
              csv_line << sale_analysis&.vendor_currency
              csv_line << sale_analysis&.exchange_rate
              csv_line << sale_analysis&.sub_total
              csv_line << sale_analysis&.tax_inclusive
              csv_line << sale_analysis&.additional_tax
              csv_line << sale_analysis&.shipping_amount
              csv_line << sale_analysis&.total_shipping_amount
              csv_line << sale_analysis&.discount_amount
              csv_line << sale_analysis&.associated_order_value
              csv_line << sale_analysis&.promo_code
              csv_line << sale_analysis&.payment_method
              csv_line << sale_analysis&.shipping_method
              csv_line << sale_analysis&.order_shipped
              csv_line << sale_analysis&.tags
              csv_line << sale_analysis&.gift_card_number.join(',')
              csv_line << sale_analysis&.special_message
              csv_line << sale_analysis&.card_type
              csv_line << sale_analysis&.recipient_name
              csv_line << sale_analysis&.recipient_first_name
              csv_line << sale_analysis&.recipient_last_name
              csv_line << sale_analysis&.recipient_email
              csv_line << sale_analysis&.recipient_phone_number
              csv_line << sale_analysis&.marketing_enabled
              csv_line << sale_analysis&.product_tag
              csv << csv_line
            end
          end
        end
      end

      password = password.present? ? password : ENV['ZIP_ENCRYPTION']
      Spree::Order.add_to_zip(file_path, password)
      "#{file_path}.zip"
    end

    def generate_sale_analysis
      order_attrs = self.price_values
      @line_items = order_attrs[:line_items]
      @shipments = order_attrs[:shipments]
      total_shipping_amount = order_attrs[:prices][:ship_total]
      @line_items.each do |line_item|
        sale_analysis = Spree::SaleAnalysis.new
        sale_analysis.line_item = line_item
        sale_analysis.order = self
        item_shipmnent = @shipments.find_by('spree_shipments.line_item_id = ?', line_item.id)
        exchange_value = line_item&.saved_exchange_rate || 1
        shipping_amount = (item_shipmnent&.cost.to_f * exchange_value)

        voucher_recipent_name = line_item&.line_item_customizations&.where(name: 'Gift Card Name')&.first&.try(:value)
        sale_analysis.order_number = self&.number
        sale_analysis.storefront = self&.store&.name
        sale_analysis.vendor = line_item&.variant&.product&.vendor&.name
        sale_analysis.time_zone = "UTC"
        sale_analysis.date_placed = local_date(self.completed_at)&.strftime("%B %d, %Y")
        sale_analysis.time_placed = local_date(self.completed_at)&.strftime("%I:%M %p")
        sale_analysis.order_status = self.state
        sale_analysis.customer_full_name = self.billing_address&.full_username
        sale_analysis.customer_address = self.billing_address&.get_full_address
        sale_analysis.customer_first_name = self.billing_address&.firstname
        sale_analysis.customer_last_name = self.billing_address&.lastname
        sale_analysis.shipping_delivery_country = self.ship_address&.country&.name
        sale_analysis.customer_phone = self.billing_address&.phone
        sale_analysis.customer_email = self.user&.email || self&.email
        sale_analysis.product_name = line_item&.variant&.name
        sale_analysis.product_sku = line_item&.variant&.sku
        sale_analysis.vendor_sku = line_item&.variant&.product&.vendor_sku
        sale_analysis.variant = line_item&.variant&.options_text
        sale_analysis.product_quantity = line_item&.quantity
        sale_analysis.product_price = line_item.exchanged_prices[:sub_total]
        sale_analysis.delivery_pickup_date = item_shipmnent&.delivery_pickup_date&.strftime("%B %d, %Y")
        sale_analysis.delivery_pickup_time = item_shipmnent&.delivery_pickup_time
        sale_analysis.shipped_date = local_date(item_shipmnent&.shipped_at)&.strftime("%B %d, %Y")
        sale_analysis.shipped_time = local_date(item_shipmnent&.shipped_at)&.strftime("%I:%M %p")
        sale_analysis.order_currency = line_item.line_item_exchange_rate&.to_currency
        sale_analysis.vendor_currency = line_item.line_item_exchange_rate&.from_currency
        sale_analysis.exchange_rate = line_item.line_item_exchange_rate&.exchange_rate
        sale_analysis.sub_total = line_item.exchanged_prices[:amount]
        sale_analysis.tax_inclusive = "%.2f" % line_item.total_tax(:included)
        sale_analysis.additional_tax = "%.2f" % line_item.total_tax(:additional)
        sale_analysis.shipping_amount = shipping_amount
        sale_analysis.total_shipping_amount = total_shipping_amount
        sale_analysis.discount_amount = self.exchanged_prices[:promo_total]
        sale_analysis.associated_order_value = self.exchanged_prices[:total]
        sale_analysis.promo_code = self.promo_code
        sale_analysis.payment_method = self.payments.completed.map {|k| k.payment_method&.name}.join(', ')
        sale_analysis.shipping_method = line_item.shipping_method_name
        sale_analysis.order_shipped = self.shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
        sale_analysis.tags = self&.order_tags&.pluck('label_name')&.join(',')
        sale_analysis.gift_card_number = "#{line_item.gift_card_number}"
        sale_analysis.gift_card_iso_number = "#{line_item.gift_card_iso_number}"
        sale_analysis.special_message = line_item&.message
        sale_analysis.card_type = spo_genre || line_item&.delivery_mode
        sale_analysis.recipient_name = (line_item&.variant.present? && line_item.is_gift_card? ? voucher_recipent_name : "#{line_item&.receipient_first_name} #{line_item&.receipient_last_name}")
        sale_analysis.recipient_first_name = (line_item&.variant.present? && line_item.is_gift_card? ? voucher_recipent_name : line_item&.receipient_first_name)
        sale_analysis.recipient_last_name = (line_item&.variant.present? && line_item.is_gift_card? ? voucher_recipent_name : line_item&.receipient_last_name)
        sale_analysis.recipient_email = (line_item&.variant.present? && line_item.is_gift_card? ? line_item&.line_item_customizations&.where(name: 'Gift Card Email')&.first&.try(:value) : line_item.receipient_email)
        sale_analysis.recipient_phone_number = line_item&.receipient_phone_number
        sale_analysis.marketing_enabled = (self.enabled_marketing ? 'Yes' : self.news_letter ? 'Default' : 'No')
        sale_analysis.product_tag = line_item&.variant&.product&.tag_list&.first
        sale_analysis.order_subtotal = self.exchanged_prices[:payable_amount]
        sale_analysis.unit_cost_price = (!line_item&.variant&.unit_cost_price&.zero? ? line_item&.variant&.unit_cost_price : line_item&.variant&.product&.unit_cost_price)
        sale_analysis.barcode_number = (line_item&.variant&.barcode_number.present? ? line_item&.variant&.barcode_number : line_item&.variant&.product&.barcode_number)
        sale_analysis.brand_name = line_item&.variant&.product&.brand_name&.to_s
        sale_analysis.product_card_type = line_item&.product&.ts_type
        sale_analysis.save
      end
    end

    def generate_vendor_sale_analysis
      vendor_ids = self&.shipments.pluck(:vendor_id).uniq
      Spree::Vendor.where(id: vendor_ids).each do |vendor|
        base_currency = vendor&.base_currency&.name
        price_values = self.price_values(base_currency, vendor&.id)
        shipment = self.shipments.where(vendor_id: vendor&.id).first
        shipment_state = shipment&.state&.to_s
        vendor_sale_analysis = Spree::VendorSaleAnalysis.new
        vendor_sale_analysis.vendor = vendor
        vendor_sale_analysis.order = self
        vendor_sale_analysis.number = self&.number
        vendor_sale_analysis.storefront = self&.store&.name
        vendor_sale_analysis.completed_at = self&.completed_at
        vendor_sale_analysis.status = shipment_state
        vendor_sale_analysis.email = self&.user&.email || self&.email
        vendor_sale_analysis.currency = base_currency
        vendor_sale_analysis.delivery_pickup_date = shipment&.delivery_pickup_date&.strftime("%B %d, %Y")
        vendor_sale_analysis.delivery_pickup_time = shipment&.delivery_pickup_time
        vendor_sale_analysis.shipped_date = local_date(shipment&.shipped_at)&.strftime("%B %d, %Y")
        vendor_sale_analysis.shipped_time = local_date(shipment&.shipped_at)&.strftime("%I:%M %p")
        vendor_sale_analysis.tax_inclusive = price_values[:prices][:included_tax_total]
        vendor_sale_analysis.additional_tax = price_values[:prices][:additional_tax_total]
        vendor_sale_analysis.tags = self&.order_tags&.pluck('label_name')&.join(',')
        vendor_sale_analysis.total = price_values[:prices][:payable_amount]
        vendor_sale_analysis.save
      end
    end

    def store_calculated_price_values
      return if self.calculated_price.present?
      begin
        order_meta_data = { promo_code: self.promo_code, payment_method: self.payments.completed.map { |k| k.payment_method.name }.join(', ') }
      rescue
        order_meta_data = { promo_code: self.promo_code, payment_method: "" }
      end
      # store_calculated_price_values in order currency
      Spree::CalculatedPrice.find_or_initialize_by(calculated_price: self, to_currency: self.currency, calculated_value: self.price_values, meta: order_meta_data).tap do |calculated_price|
        calculated_price.save! unless calculated_price.persisted?
      end
      self.price_values[:line_items].find_each do |line_item|
        line_item_meta_data = { options_text: line_item&.variant&.options_text, shipping_method_name: line_item&.shipping_method_name,tag_list: line_item&.variant&.product&.tag_list&.first }
        Spree::CalculatedPrice.find_or_initialize_by(calculated_price: line_item, to_currency: line_item.currency, calculated_value: line_item.price_values, meta: line_item_meta_data).tap do |calculated_price|
          calculated_price.save! unless calculated_price.persisted?
        end
      end

      # store calculated price values in client currency
      client = self&.store&.client
      client_currency = client&.reporting_currency
      if client.present? && client_currency.present? && client_currency != self.currency
        Spree::CalculatedPrice.find_or_initialize_by( calculated_price: self, to_currency: client_currency,calculated_value: self.price_values(client_currency),  meta: order_meta_data).tap do |calculated_price|
          calculated_price.save! unless calculated_price.persisted?
        end

        self.price_values[:line_items].find_each do |line_item|
          line_item_meta_data = { options_text: line_item&.variant&.options_text, shipping_method_name: line_item&.shipping_method_name,tag_list: line_item&.variant&.product&.tag_list&.first }
          Spree::CalculatedPrice.find_or_initialize_by( calculated_price: line_item, to_currency: client_currency,
          calculated_value: line_item.price_values(client_currency), meta: line_item_meta_data).tap do |calculated_price|
            calculated_price.save! unless calculated_price.persisted?
          end
        end
      end
    end

    def send_order_emails
      if store.ses_emails
        SesEmailsDataWorker.perform_async(id, "order_confirmation_customer")
        SesEmailsDataWorker.perform_async(id, "order_confirmation_vendor")
      else
        Spree::OrderMailer.confirm_email(id).deliver_later
        Spree::OrderMailer.email_to_vendors(self)
      end
      Spree::OrderMailer.notify_balance_due(id).deliver_later if self.payment_state.eql?("balance_due")
      shipments.shipped.each do |shipment|
        if store.ses_emails
          SesEmailsDataWorker.perform_async(shipment.id, "regular_shipment_customer")
        else
          Spree::ShipmentMailer.shipped_email(shipment.id).deliver_now
        end
      end
      givex_cards.is_generated.each do |givex_card|
        if store.ses_emails
          SesEmailsDataWorker.perform_async(givex_card.id, "digital_givex_card_recipient")
        else
          Spree::GeneralMailer.send_givex_cadentials_to_customer(givex_card).deliver_now
        end
      end
      ts_giftcards.is_generated.each do |ts_giftcard|
        if store.ses_emails
          SesEmailsDataWorker.perform_async(ts_giftcard.id, "digital_ts_card_recipient")
        else
          Spree::GeneralMailer.send_ts_cadentials_to_customer(ts_giftcard).deliver_now
        end
      end
    end

    def ensure_line_items_are_in_stock
      if insufficient_stock_lines.present?
        restart_checkout_flow
        insufficient_variants_name = insufficient_stock_lines.group_by(&:variant).map do |variant, line_items|
          display_name = variant.name.to_s
          display_name += " (#{variant.options_text})" unless variant.options_text.blank?
          display_name
        end.join("; ")
        errors.add(:base, Spree.t(:insufficient_stock_lines_present, product_name: insufficient_variants_name))
        false
      else
        true
      end
    end

    def payments_with_giftcard
      payments.gift_cards.valid.map{ |gift| { code: gift.source.code, amount: gift.amount}}
    end

    def tax_zone(fulfilment_zone=false)
      # @tax_zone ||= Zone.match(tax_address) || Zone.default_tax
      @tax_zone ||= Spree::Zone.match(tax_address,fulfilment_zone)
      @tax_zone ||= store.default_tax_zone unless tax_address.present?
      @tax_zone
    end

    def tax_labels
      return {
        inclusive: (store&.included_tax_label.presence || "Tax Inclusive of prices"),
        exclusive: (store&.excluded_tax_label.presence || "Tax Exclusive of prices")
      }
    end

    def all_digital?
      line_items.all?{ |s| DIGITAL_TYPES.include?s.delivery_mode}
    end

    def all_physical?
      line_items.all?{ |s| PHYSICAL_TYPES.include?s.delivery_mode}
    end

    def customer_name
      return "" unless bill_address.present?

      "#{bill_address.firstname} #{bill_address.lastname}"
    end

  # Applies promotions for specific (now only for stripe) bin codes
    attr_accessor :bincode
    def apply_bin_code_promotions(bin)
      self.bincode = bin
      ::Spree::PromotionHandler::CardBinCode.new(self).activate
      save
    end

    def promotion_applicable?
      discount_amount = self.price_values(self.currency)[:prices][:promo_total].to_f.abs

      (self.line_items.none?{ |li| li.product.on_sale? }) &&
      ((self.promotions.none?{ |p| p.code.blank? }) ||
      (self.promotions.any?{ |p| p.code.blank? } && discount_amount.zero?) ||
      (self.promotions.any?{ |p| p.code.present? } && !discount_amount.zero?))
    end

    def apply_unassigned_promotions
      ::Spree::PromotionHandler::Cart.new(self).activate
    end

    def cash_on_delivery? # There will be only payment for cash on delivery
      return false unless self.payments.processable.present?

      self.payments.processable.last.payment_method.type.eql? "Spree::PaymentMethod::CashOnDelivery"
    end

    def shipment_count_should_be
      query = "SELECT COUNT(DISTINCT (CASE
        WHEN spree_line_items.delivery_mode = 'givex_digital' OR spree_line_items.delivery_mode = 'tsgift_digital' THEN CONCAT_WS('.',spree_line_items.vendor_name,spree_line_items.delivery_mode,spree_line_items.id)
        WHEN spree_line_items.delivery_mode = 'food_pickup' OR spree_line_items.delivery_mode = 'food_delivery' THEN CONCAT_WS('.',spree_line_items.vendor_name,spree_line_items.delivery_mode,spree_line_items.shipping_category)
        ELSE CONCAT_WS('.',spree_line_items.vendor_name,spree_line_items.delivery_mode)
        END)) AS shipments_count
      FROM spree_line_items
      WHERE spree_line_items.order_id = #{self.id};"
      ActiveRecord::Base.connection.execute(query).first["shipments_count"]
    end

    def digital?
      line_items.all? { |item| DIGITAL_TYPES.include?(item.delivery_mode) }
    end

    def get_order_spreadsheet_data
      data = []
      billing_address = self.billing_address
      shipment_state = self.shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
      payment_method = self.payments.completed.map {|k| k.payment_method.name}.join(', ')
      promo_code = self&.promotions&.map(&:code)&.join(", ")
      customer_name = billing_address&.full_username
      enabled_marketing = (self.enabled_marketing ? 'Yes' : 'No')
      order_attrs = self.price_values
      @line_items = order_attrs[:line_items]
      @shipments = order_attrs[:shipments]
      @line_items.each do |line_item|
        item_shipmnent = @shipments.find_by('spree_shipments.line_item_id = ?', line_item.id)
        next if line_item.variant.blank? || line_item.product.blank?
        data << line_item.generate_csv_data(self, item_shipmnent, shipment_state, payment_method, promo_code, customer_name, enabled_marketing)
      end
      return data
    end

    def single_page_order?
      self.complete? ? self.preferred_single_page : self.store.preferred_single_page
    end

  def create_test_order_tags
    return unless self.store&.test_mode
    client = self.store&.client
    client_email = client.email || client.users.with_role('client')&.email
    order_tag = client.order_tags.find_by("replace(lower(label_name), ' ', '') = replace(?, ' ', '')", :'test order'.to_s)
    order_tag ||= client.order_tags.create(label_name: :'Test Order'.to_s, intimation_email: client_email)

    if order_tag.present? && self.order_tags.ids.exclude?(order_tag.id)
      self.order_tags << order_tag
      self.update_sale_analyses if self.save!
      order_tag_order = Spree::OrderTagsOrder.find_by(order_tag: order_tag, order: self)
      order_tag_order.send_email_tag_added_to_intimation if order_tag_order.present?
    end
  end

  def product_quantities
    line_items.group_by(&:product_id).each_with_object({}) do |grouped_items, hash|
      hash[grouped_items[0]] = grouped_items[1].sum(&:quantity)
    end
  end

  private

  def update_number_prefix_suffix
    return if store&.prefix.blank? && store&.suffix.blank?
    order_number = store&.prefix.to_s + number + store&.suffix.to_s
    self.update_column(:number, order_number)
  end

    def get_new_cart_token
      id.to_s(16).concat(SecureRandom.urlsafe_base64).concat(DateTime.now.to_i.to_s(16))
    end

    def paid_completely
      # Set still pending payments as failed if complete payment received
      self.price_values # Must be called to use exchanged order prices
      self.payments.pending.each(&:failure) if self.payment_total >= BigDecimal(self.exchanged_prices[:payable_amount])

      remaining_balance = self.outstanding_balance
      if remaining_balance.positive?
        self.errors.add(:base, Spree.t(:order_amount_due, amount: self.display_exchanged(remaining_balance)))
        false
      else
        true
      end
    end

    def collect_payment_methods(storefront = store)
      storefront ||= store
      payment_methods = storefront.try(:payment_methods)
      payment_methods ||= storefront.try(:client).try(:payment_methods)
      # payment_methods ||= Spree::PaymentMethod.all
      payment_methods.distinct.available_on_front_end.select { |pm| pm.available_for_order?(self) }
    end

    def capture_stripe_payment
      return if self.store.stripegateway_payment_method.blank? || self.payment_intent_id.blank?

      # Capture amount
      Stripe.api_key = self.store.stripegateway_payment_method.preferred_secret_key
      Stripe.stripe_account = self.store.send(:stripe_connected_account)

      # Payment Intent has already been captured for alipay and wechat
      unless Spree::Payment.class_eval{STRIPE_WALLETS}.include?(payments.last&.source&.name)
        stripe_payment_intent = Stripe::PaymentIntent.capture(self.payment_intent_id)
      end

      # attach stripe customer to payment intent
      stripe_customer = Stripe::Customer.create({ name: self.customer_name, email: self.email })
      payment_intent_attrs = { customer: stripe_customer.id }

      stripe_payment = self.payments.joins(:payment_method)
                          .where('spree_payment_methods.type = ?', 'Spree::Gateway::StripeGateway')
                          .completed.last

      # update description if successfully paid
      payment_intent_attrs[:description] = "Techsembly Order ID: #{self.number}-#{stripe_payment.number}" if stripe_payment.present?

      Stripe::PaymentIntent.update(self.payment_intent_id, payment_intent_attrs)
    end

    def cancel_stripe_payment
      return unless self.payment_intent_id.present?

      Stripe.api_key = self.store.stripegateway_payment_method.preferred_secret_key
      Stripe.stripe_account = self.store.send(:stripe_connected_account)
      Stripe::PaymentIntent.cancel(self.payment_intent_id)

      self.update_column(:payment_intent_id, nil)
    end

    def homogenize_bulk_order
      return unless self.bulk_order.present?
      self.bulk_order.update_column(:state, self.state)
    end
  end
end

::Spree::Order.prepend Spree::OrderDecorator if ::Spree::Order.included_modules.exclude?(Spree::OrderDecorator)
