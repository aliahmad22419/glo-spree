module Spree
  module Payment
    module GatewayOptionsDecorator
      APP_FEE_TYPES = { percentage: 'percentage', flat_rate: 'flat_rate' }.freeze

      def application_fee
        return nil unless stripe?
        client = order.store.client
        fee = client.app_fee
        fee = (fee * destination_amount / 100) if client.app_fee_type == APP_FEE_TYPES[:percentage]
        fee = fee.to_i # cents
        return (fee < 50 ? nil : fee)
      end

      def store_url
        order.store.url
      end

      def on_behalf_of
        stripe_express_account
      end

      def stripe_account
        stripe_standard_account
      end

      def order_token
        order.token
      end

      def destination
        stripe_express_account
      end

      def splits
        # return [] unless splitable? # implemented only for adyen
        # order.payment_splits
        return []
      end

      def order_id
        "#{order.number}-#{@payment.number}"
      end

      def order_reference_id
        "Techsembly Order ID: #{order_id}"
      end

      def destination_amount
        BigDecimal(order.price_values(order.currency)[:prices][:cents]).to_i
      end

      def payment_intent_id
        order.payment_intent_id
      end

      def customer_name
        order.customer_name
      end

      def stripe_connected_account
        order.completed_at.present? ? order.preferred_stripe_connected_account.presence : order.store.stripe_connected_account.presence
      end

      def hash_methods
        [
          :email,
          :customer,
          :customer_name,
          :customer_id,
          :ip,
          :order_id,
          :shipping,
          :tax,
          :subtotal,
          :discount,
          :currency,
          :billing_address,
          :shipping_address,
          :store_url,
          :application_fee,
          :stripe_account,
          :order_token,
          :splits,
          :on_behalf_of,
          :destination,
          :destination_amount,
          :order_reference_id,
          :stripe_connected_account,
          :payment_intent_id,
          :refund_reason
        ]
      end

      private

      def payment_intent_id
        order.payment_intent_id
      end

      def refund_reason
        @payment.refunds.order(created_at: :asc).last&.reason&.name
      end

      def stripe_express_account
        order.store.stripe_express_account_id.presence if stripe?
      end

      def stripe_standard_account
        order.store.stripe_standard_account_id.presence if stripe?
      end

      def stripe?
        @payment.payment_method.type.eql?("Spree::Gateway::StripeGateway")
      end

      def splitable?
        @payment.payment_method.type == "Spree::Gateway::AdyenGateway"
      end
    end
  end
end

::Spree::Payment::GatewayOptions.prepend(Spree::Payment::GatewayOptionsDecorator)  unless ::Spree::Payment::GatewayOptions.ancestors.include?(Spree::Payment::GatewayOptionsDecorator )
