module Spree
  module PaymentTokenConcern
    def self.included(base)
      base.class_eval do
        before_action :payment_method, only: [:braintree_client]
        before_action :ensure_stripe_payment_method, only: [:stripe_client_secret]

        def adyen_payment?
          payments_attributes = params[:order][:payments_attributes] if params[:order]
          payments_attributes = payments_attributes[0] if payments_attributes
          pm_id = payments_attributes[:payment_method_id] if payments_attributes
          return false unless pm_id.present?
          @adyen_payment_method = spree_current_store&.payment_methods&.active
                                                    &.find_by_type("Spree::Gateway::AdyenGateway")
          @adyen_payment_method.present? && @adyen_payment_method.id.to_s.eql?(pm_id.to_s)
        end

        def adyen_three_ds
          source = Spree::AdyenCheckout.find_by('spree_adyen_checkouts.id = ?', params[:source])
          return if source.blank?
          three_ds_data = params.to_unsafe_h.except(*[:action, :controller, :format, :order_token, :source])
          source.three_ds_action['data'] = three_ds_data
          source.save
          begin
            source.payment.authorize3d!
          rescue Spree::Core::GatewayError => e
            redirect_to "#{spree_current_store&.subfoldering_url}/checkout?payment_error=#{e.message}" and return
          end

          redirect_to "#{spree_current_store&.subfoldering_url}/checkout/complete" and return
        end

        def braintree_client
          client_token = payment_method&.client_token(spree_current_order)
          if client_token.present?
            render json: { token: client_token }, status: 200
          else
            render_error_payload("Invalid paypal client request", 403)
          end
        end

        def stripe_client_secret
          order_prices = spree_current_order.price_values[:prices]
          store = spree_current_order.store
          Stripe.api_key = store.stripegateway_payment_method.preferred_secret_key
          Stripe.stripe_account = store.send(:stripe_connected_account)

          begin
            # intent_already_updated = if spree_current_order.payment_intent_id.present?
            #   Stripe.stripe_account = store.send(:stripe_connected_account)
            #   payment_intent = Stripe::PaymentIntent.retrieve(spree_current_order.payment_intent_id)
            #
            #   ( payment_intent.payment_method_types.eql?(params[:payment_method_type]) &&
            #     payment_intent.currency.eql?(spree_current_order.currency.downcase) &&
            #     payment_intent.amount.eql?(order_prices[:cents]) )
            # else false end
            intent_already_updated = false # always create new payment intent
            unless intent_already_updated
              spree_current_order.send(:cancel_stripe_payment)

              # Check if stripe payment method is of type credit card
              if params.present? && params[:stripe_pm].present?
                spm = Stripe::PaymentMethod.retrieve(params[:stripe_pm], stripe_account: store.send(:stripe_connected_account))
                bincode_promotable = BigDecimal(order_prices[:gc_total]).zero? &&
                                     BigDecimal(order_prices[:promo_total]).zero? &&
                                     spree_current_order.line_items.none?{ |li| li.product.on_sale? } &&
                                     (spm.present? && spm['card'].present? && spm['card']['iin'].present?)

                if bincode_promotable
                  spree_current_order.apply_bin_code_promotions(spm['card']['iin'])
                  order_prices = spree_current_order.reload.price_values[:prices]
                end
              end

              intent_metadata = {}
              intent_metadata[:sabre_reference_code] = store.sabre_reference_code if store.sabre_reference_code.present?

              payment_intent = Stripe::PaymentIntent.create(
                {
                  payment_method_types: params[:payment_method_type],
                  capture_method: (Spree::Payment.class_eval{STRIPE_WALLETS}.include?(params[:payment_method_type][0]) ? 'automatic' : 'manual'), # Just authorize payment
                  amount: order_prices[:cents],
                  currency: spree_current_order.currency.downcase,
                  description: "Techsembly Order ID: #{spree_current_order.number}",
                  on_behalf_of: nil,
                  statement_descriptor: store.preferred_stripe_statement_descriptor_suffix,
                  statement_descriptor_suffix: store.preferred_stripe_statement_descriptor_suffix,
                  metadata: intent_metadata,
                  transfer_data: {
                    destination: nil
                  }
                }, stripe_account: store.send(:stripe_connected_account)
              )

              spree_current_order.update_column(:payment_intent_id, payment_intent.id)
            end
          rescue => e
            render_error_payload(e.message, 404) and return
          end

          render json: { client_secret: payment_intent.client_secret, confirmed: payment_intent.status.eql?('requires_capture') }, status: 200
        end

        private

        def payment_method
          Spree::PaymentMethod.find_by_type("Spree::Gateway::BraintreeVzeroHostedFields")
        end

        # allowed payment method types are ['wechat_pay', 'alipay', 'card']
        def ensure_stripe_payment_method
          currs = %w(AUD CAD CNY EUR GBP HKD JPY SGD USD DKK NOK SEK CHF)
          is_stripe_wallet = (Spree::Payment.class_eval{ STRIPE_WALLETS } & params[:payment_method_type]).any?

          render_error_payload("#{spree_current_order.currency} is not supported", 405) and
            return if is_stripe_wallet && currs.exclude?(spree_current_order.currency)
        end
      end
    end
  end
end
