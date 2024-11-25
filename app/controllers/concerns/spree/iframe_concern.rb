module Spree
  module IframeConcern
    def self.included(base)
      base.class_eval do
        skip_before_action :ensure_order, only: :create_iframe_cart
        before_action :destroy_order, only: :create_iframe_cart, if: Proc.new { params[:order_token] }
        before_action :set_order, only: [:destroy_order]

        def create_iframe_cart
          begin 
            result = iframe_checkout.call(
              user: nil,
              store: spree_current_store,
              currency: current_currency,
              order_params: iframe_cart_params,
              options: params
            )
            if result.success?
              render_serialized_payload(201) { serialize_order(result.value) }
            else
              render_error_payload(result.error)
            end
          rescue Exception => exception
            render_error_payload(exception.message,422)
          end
        end

        def reset_iframe_order_state
          if (spree_current_order.confirm? && !spree_current_order.payments.completed.any?)
            spree_current_order.update(state: 'payment')
          end
        end

        private

        def set_order
          @order = Spree::Order.find_by(token: params[:order_token])
        end

        def destroy_order
          if @order.present?
            @order.destroy unless @order.complete?
          end
        end

        def iframe_checkout
          Iframe::Checkout.new
        end

        def iframe_cart_params
          { email: params[:email] }
        end

      end
    end
  end
end