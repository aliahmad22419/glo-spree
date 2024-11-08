module Spree
  module V2
    module Storefront
      class CartSerializer < BaseSerializer
        set_type :cart

        attributes :id, :number, :item_total, :total, :ship_total, :adjustment_total, :created_at,
                   :updated_at, :completed_at, :included_tax_total, :additional_tax_total, :display_additional_tax_total,
                   :display_included_tax_total, :tax_total, :currency, :state, :token, :email, :store_id,
                   :display_item_total, :display_ship_total, :display_adjustment_total, :display_tax_total, :coupon_code,
                   :promo_total, :display_promo_total, :item_count, :special_instructions, :display_total, :considered_risky,
                   :total_applied_gift_card, :paid_partially, :last_payment_is, :delivery_type, :labels, :promo_code, :cart_token,
                   :product_quantities

        attribute :currency_symbol do |cart, params|
          Spree::Money.new(params[:default_currency]).currency.symbol
        end

        attribute :line_items_with_both_types do |object, params|
          Spree::V2::Storefront::LineItemSerializer.new(object.line_items.where(delivery_mode: GIFTCARD_WITH_BOTH_TYPE), params: params).serializable_hash
        end

        attribute :customer_status do |object, params|
          customer_status = params[:store]&.orders&.complete&.where(email: object.email).count > 1 ? "Returning" : "New"
          customer_status
        end

        attribute :line_items_with_types do |object, params|
          grouped_line_items = {}
          blocked_dates = {}
          object.line_items.where(delivery_mode: FOOD_TYPES).group_by{|e| [e.vendor_name, e.delivery_mode, e.shipping_category, e.product&.effective_date.to_s]}.each do |vendor_name, line_items|
            grouped_line_items[vendor_name] = Spree::V2::Storefront::LineItemSerializer.new(line_items, params: params).serializable_hash
            blocked_dates[vendor_name] = line_items.map(&:product).map(&:blocked_dates).flatten.map{ |range| eval(range) }
                                             .map{ |r| (Date.parse(r['start_date'])..Date.parse(r['end_date'])).to_a rescue []}
                                             .flatten.map(&:to_s).uniq
          end
          object.line_items.where.not(delivery_mode: FOOD_TYPES).group_by{|e| [e.vendor_name, e.delivery_mode]}.each do |vendor_name, line_items|
            delivery_mode = vendor_name[1]
            if DIGITAL_TYPES.include?(delivery_mode)
              line_items.each{|line_item| grouped_line_items[vendor_name + [line_item.id.to_s]] = Spree::V2::Storefront::LineItemSerializer.new([line_item], params: params).serializable_hash}
            else
              grouped_line_items[vendor_name] = Spree::V2::Storefront::LineItemSerializer.new(line_items, params: params).serializable_hash
            end
          end
          [grouped_line_items, blocked_dates]
        end

        attribute :shipments_count do |object|
          object.shipments.select{|shipment| shipment.selected_shipping_rate.present?}.count
        end

        attribute :pickup_and_digital do |object|
          type, line_items = "", object.line_items
          type = "pickup_and_digital" if line_items.any?{ |s| s.delivery_mode == 'food_pickup' } && line_items.any?{ |s| DIGITAL_TYPES.include?s.delivery_mode } && !line_items.any?{ |s| DIGITAL_TYPES.include?s.delivery_mode && s.delivery_mode == 'food_pickup' }
          type
        end

        attribute :all_line_items_type do |object|
          type = "all"
          line_items = object.line_items
          if line_items.all?{ |s| s.is_gift_card == true }
            type = "voucher"
          elsif line_items.all?{ |s| DIGITAL_TYPES.include?s.delivery_mode}
            type = "digital"
          elsif line_items.all?{ |s| PHYSICAL_TYPES.include?s.delivery_mode}
            type = "physical"
          elsif line_items.all?{ |s| s.delivery_mode == 'food_pickup' }
            type = "pickup"
          elsif line_items.any?{ |s| PHYSICAL_TYPES.include?s.delivery_mode }
            type = "at-least-one-physical"
          end
          type
        end

        attribute :pickup_address do |object|
          Spree::V2::Storefront::AddressSerializer.new(object&.store&.pickup_address).serializable_hash
        end

        attribute :shipments do |cart, params|
          shipments_obj = []
          cart.shipments.each do |shipment|
            selected_rate = shipment.shipping_rates.where(selected: true).first
            if selected_rate.present?
              ship_rate = selected_rate.attributes.except("created_at", "updated_at")
              li = cart.line_items.find(shipment.line_item_id)
              ship_rate["cost"] = li.tp(ship_rate["cost"] * li.apply_exchange_rate(params[:default_currency]), params[:default_currency])
              ship_rate["vendor_id"] = shipment.vendor_id
              ship_rate["method_name"] = selected_rate.shipping_method.name
              shipments_obj << ship_rate
            end
          end
          shipments_obj
        end

        attribute :valid_for_promotional_code do |object|
          object.promotion_applicable?
        end

        attribute :price_values do |object, params|
          object.price_values(params[:default_currency])[:prices]
        end

        attribute :giftcard_payment do |cart, params|
          Spree::Config.allow_gift_card_partial_payments &&
          cart.payments.valid.last&.source_type.eql?("Spree::GiftCard") &&
          cart.price_values[:prices][:payable_amount].to_f > 0 ?
          'partial' : 'complete'
        end

        attribute :giftcard_payments do |cart, params|
          cart.payments_with_giftcard
        end

        attribute :payment_source do |object|
          object.payments.completed.map {|k| k.card_details}
        end

        attribute :adyen_checkout_source do |object|
          object.payments.where("source_type <> ? AND state NOT IN (?)", "Spree::GiftCard", ["invalid", "failed"]).order(created_at: :asc).last.try(:source)
        end

        attribute :payment_method_name do |cart|
          cart.payments&.completed&.last&.payment_method&.name
        end

        attribute :eghl_hash do |cart, params|
          store = cart.store
          host_url = "https://" + store.url
          payment_method = store.payment_methods.find_by(type: "Spree::Gateway::Eghl", active: true)
          if payment_method.present?

            if payment_method.preferences[:server] == "live"
              eghl_url = "https://securepay.e-ghl.com/IPG/Payment.aspx"
            else
              eghl_url = "https://pay.e-ghl.com/IPGSG/Payment.aspx"
            end

            amount = cart.price_values(params[:default_currency])[:prices][:payable_amount]
            amount = '%.2f' % amount
            currency_val = amount + "THB"
            payment_id = rand(36**8).to_s(36)
            hash_value = Digest::SHA256.hexdigest(payment_method.preferences[:merchant_password] + payment_method.preferences[:merchant_id] + payment_id + host_url + "/api/v2/storefront/response_eghl" + host_url + "/api/v2/storefront/response_eghl_call_back" +  currency_val + "900" )
            { payment_id: payment_id, hash: hash_value, amount: amount, host_url: host_url, eghl_url: eghl_url }
          else
            { host_url: host_url }
          end
        end

        has_many   :variants
        has_many   :promotions, object_method_name: :valid_promotions, id_method_name: :valid_promotion_ids
        has_many   :payments do |cart|
          cart.payments.valid
        end

        attribute :link_payment do |object|
          source = object.payments.joins(:payment_method).find_by(
            state: 'checkout', spree_payment_methods: { type: 'Spree::Gateway::LinkPaymentGateway' })&.source
          { gateway_reference: source&.gateway_reference, url: source&.url, updated_at: source&.updated_at }
        end

        attribute :user_id do |cart|
          cart.user_id
        end

        belongs_to :user
        belongs_to :billing_address,
          id_method_name: :bill_address_id,
          serializer: :address

        attribute :shipping_address do |object|
          Spree::V2::Storefront::AddressSerializer.new(object.shipping_address).serializable_hash
        end

        attribute :store_tax_labels do |cart|
          cart.tax_labels
        end

        attribute :total_line_items do |cart|
          cart.line_items.count
        end

        attribute :store_notes do |cart|
          cart.store&.note
        end

        attribute :iframe_shipment_type do |cart|
          cart&.line_items&.first&.shipment_type
        end

        attribute :iframe_card_generation_datetime do |cart|
          cart&.shipments&.first&.card_generation_datetime
        end
      end
    end
  end
end
