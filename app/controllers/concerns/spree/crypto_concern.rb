module Spree
  module CryptoConcern
    CRYPTO_API = "https://pay.crypto.com/api/payments"
    
    def self.included(base)
      base.class_eval do
        before_action :set_order_payment, only: [:complete_crypto_payment]
        before_action :cancel_payment_intents, only: [:crypto_payment]        #cancel pervious payment intents before creating new

        def complete_crypto_payment
          result = update_service.call(
            order: spree_current_order,
            params: order_payment_params,
            permitted_attributes: permitted_checkout_attributes,
            request_env: request.headers.env
          )
          spree_current_order.next!
          if spree_current_order.errors.any?
            render_error_payload(failure(spree_current_order).error)
          else
            render_order(result)
          end
        end

        def crypto_payment
          payment_response = create_crypto_payment
          if payment_response.success?
            create_intent(payment_response.parsed_response)
            spree_current_order.next! unless spree_current_order.payment?
          end
          render json: payment_response, status: payment_response.code
        end

        private
        def order_payment_params
          payment =  @order_payment
          render_no_payment if payment.blank?
          order_params = ActionController::Parameters.new({
            "order": {
              "payments_attributes": [{
                "payment_method_id": params[:payment_method_id],
                "source_attributes": {
                  "crypto_amount": payment['crypto_amount'],
                  "crypto_currency": payment['crypto_currency'],
                  "customer_id": payment['customer_id'],
                  "track_id": payment['id'],
                  "source_name": payment['payment_source'],
                  "status": payment['status']
                }
              }] 
            }
          })
          @order_payment_params = payment["status"] == "succeeded" ? order_params : ActionController::Parameters.new
        end

        def create_crypto_payment
          return_url = "https://#{spree_current_order.store.url}/checkout/crypto-success?payment_method_id=#{params[:payment_method_id]}"
          cancel_url = "https://#{spree_current_order.store.url}/checkout"

          HTTParty.post(CRYPTO_API, body: {
            currency: spree_current_order.currency.upcase,
            amount: spree_current_order.price_values[:prices][:cents],
            order_id: spree_current_order.number,
            description: spree_current_order.store.preferred_stripe_statement_descriptor_suffix,
            return_url: return_url,
            cancel_url: cancel_url,
          }, headers: {
            Authorization: auth_header
          })
        end

        def cancel_payment_intents
          spree_current_order.payment_intents.initiated.each do |payment_intent| 
            response = cancel_crypto_payment(payment_intent.track_id) 
            payment_intent.canceled! if response.success?
          end
        end

        def cancel_crypto_payment(track_id)
          HTTParty.post("#{CRYPTO_API}/#{track_id}/cancel", headers: {
            Authorization: auth_header
          })
        end

        def render_no_payment
          render json: {error: "payment must exist"}, status: 422
        end

        def set_order_payment
          crypto_payment_intent = spree_current_order.payment_intents.active
          if crypto_payment_intent.present?
            payment_response = HTTParty.get("#{CRYPTO_API}/#{crypto_payment_intent.track_id}",
              headers: {
                Authorization: auth_header 
            }) 
            @order_payment = payment_response&.success? ? payment_response.parsed_response : nil
          else
            render_no_payment
          end
        end

        def create_intent(crypto_payment)
          spree_current_order.payment_intents.create({
            track_id: crypto_payment["id"],
            currency: crypto_payment["currency"],
            amount: crypto_payment["amount"],
            method_type: "CryptoGateway"
          })
        end

        def auth_header
          "Basic #{Base64.strict_encode64(spree_current_order.store.cryptogateway_payment_method.preferred_secret_key)}"
        end
      end
    end
  end
end
