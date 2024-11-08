module Spree
  module V2
    module Storefront
      class OrderSerializer < BaseSerializer
        set_type :order

        attributes :id, :number, :item_total, :total, :state, :adjustment_total, :user_id, :completed_at,
                   :bill_address_id, :ship_address_id, :payment_total, :shipment_state, :payment_state, :email,
                   :created_at, :status, :updated_at, :shipment_total, :additional_tax_total, :currency,
                   :considered_risky, :coupon_code, :total_applied_gift_card, :paid_partially, :last_payment_is,
                   :pick_up_time, :customer_comment, :customer_first_name, :customer_last_name, :labels, :preferences, :notes, :token

        attribute :formatted_completed_at do |object|
          object&.completed_at&.strftime("%B %d, %Y")
        end

        attribute :pick_up_date do |object|
          object&.pick_up_date&.strftime("%B %d, %Y")
        end

        attribute :product_type do |object|
          object.line_items&.first&.delivery_mode
        end

        attribute :store_name do |object|
          object&.store&.name
        end

        attribute :refunds_timeline do |object|
          object&.store&.refunds_timeline
        end

        attribute :formatted_completed_at do |object|
          object&.completed_at&.strftime("%B %d, %Y")
        end

        attribute :store_id do |object|
          object&.store&.id
        end

        attribute :currency_symbol do |object|
          Spree::Money.new(object.currency).currency.symbol
        end

        attribute :payments do |object|
          Spree::V2::Storefront::PaymentSerializer.new(object.payments).serializable_hash
        end

        attribute :billing_address do |object|
          Spree::V2::Storefront::AddressSerializer.new(object.billing_address).serializable_hash
        end

        attribute :shipping_address do |object|
          Spree::V2::Storefront::AddressSerializer.new(object.shipping_address).serializable_hash
        end

        attribute :created_by do |object|
          Spree::V2::Storefront::UserSerializer.new(object.created_by).serializable_hash
        end

        attribute :order_line_items_contain_gift_cards do |object, params|
          giftcard_types = ["tsgift_digital", "tsgift_physical", "givex_digital", "givex_physical", "tsgift_both", "givex_both"]
          line_item_types = object.line_items.pluck(:delivery_mode)
          ([object.givex_cards.count, object.ts_giftcards.count].sum > 0)
        end

        attribute :line_items do |object, params|
          if params[:vendor_id].present?
            shipments = object.shipments.where(vendor_id: params[:vendor_id])
          else
            shipments = object.shipments
          end
          Spree::V2::Storefront::ShipmentSerializer.new(shipments, params: params).serializable_hash
        end

        attribute :shipment_method do |object, params|
          shipments = object.shipments
          if params[:vendor_id].present?
            {state: shipments.where(vendor_id: params[:vendor_id]).all?{ |s| s.state == "shipped" }}
          else
            vendor_based_status = {}
            shipments.each{|ship| vendor_based_status[ship.vendor_id] = ship&.state}
            shipment_hash = {state: shipments.all?{ |s| s.state == "shipped" }, vendor_based_status: vendor_based_status, name: shipments.map{ |s| s.shipping_method.name rescue "" }.join(",")}
            shipment_hash[:id] = shipments[0]&.id unless object&.store&.client&.multi_vendor_store
            shipment_hash
          end
        end

        attribute :price_values do |object, params|
          object.reload.price_values(object.currency, params[:vendor_id])[:prices]
        end

        attribute :user_email do |object, params|
	        object&.email || object.user&.email
        end

        attribute :payment_source do |object|
          object.payments.completed.map {|k| k.card_details}
        end

        attribute :adyen_checkout_source do |object|
          object.payments.where("source_type <> ? AND state NOT IN (?)", "Spree::GiftCard", ["invalid", "failed"]).order(created_at: :asc).last.try(:source)
        end

        attribute :store_tax_labels do |object|
          object.tax_labels
        end

        attribute :payment_method_name do |object|
          object.payments&.completed&.last&.payment_method&.name
        end
        
        attribute :payment_method_mode do |object|
          payment_method = object.payments&.completed&.last&.payment_method
          payment_method&.preferences[:server] if payment_method&.preferences && payment_method&.preferences[:server].present?
        end

        attribute :decimal_points do |object|
          object&.store&.decimal_points
        end

        attribute :currency_formatter do |object|
          object&.store&.currency_formatter
        end

        attribute :order_tag_ids do |object|
          object.order_tags.ids.map{|id| id.to_s}
        end

        attribute :order_tag_names do |object|
          object.order_tags&.pluck('label_name')&.join(',')
        end

        # stripe_payment used for refundable checks now refund_able_payment handle this
        # attribute :stripe_payment do |object|
        #   object.shipment_state.eql?('shipped') && object.payments.joins(:payment_method).find_by(
        #     state: 'completed', spree_payment_methods: { type: 'Spree::Gateway::StripeGateway' }
        #   ).present?
        # end

        attribute :refund_able_payment do |object|
          object.shipment_state.eql?('shipped') && object.payments.joins(:payment_method).find_by(
            state: 'completed', spree_payment_methods: { type: REFUNDABLE_METHODS }
          ).present?
        end

        attribute :link_payment do |object|
          source = object.payments.joins(:payment_method).find_by(
            state: 'checkout', spree_payment_methods: { type: 'Spree::Gateway::LinkPaymentGateway' })&.source
          {gateway_reference: source&.gateway_reference, url: source&.url, updated_at: source&.updated_at}
        end

        attribute :refunds do |object|
          Spree::V2::Storefront::RefundSerializer.new(object.refunds.unscope(where: :state).order(created_at: :desc)).serializable_hash
        end

        attribute :fulfilment_processing_info do |object|
          {client_name: object&.store&.client&.name, storefront_name: object&.store&.name, order_number: object&.number, zone_name: object&.zone&.name, currency: object.currency}
        end
      end
    end
  end
end
