module Spree
  module SpoConcern
    def self.included(base)
      base.class_eval do
        skip_before_action :ensure_order, only: [:create_payment_cart, :ts_transaction_emails]
        after_action :update_payment_transaction_meta, only: [:ts_transaction_emails]
        before_action :render_ts_fullfilled, only: [:ts_card_activation, :ts_card_topup], 
          if: Proc.new{ spree_current_order.ts_fullfilled? }
        before_action :render_non_zero_cart, only: [:ts_card_activation, :ts_card_topup], 
          if: Proc.new{ spree_current_order.payment_total.positive? }

        def create_payment_cart
          result = spo_checkout.call(
            user: nil,
            store: spree_current_store,
            currency: params[:currency],
            order_params: payment_cart_params,
            line_item_options: line_item_options
          )
          if result.success?
            render_serialized_payload(201) { serialize_order(result.value) }
          else
            render_error_payload(result.error)
          end
        end

        def ts_card_topup
          result = spo_checkout.ts_card_topup(
            order: spree_current_order,
            card_params: ts_card_params
          )
          render json: result.parsed_response, status: result.code || result["status"]
        end

        def ts_card_activation
          result = spo_checkout.ts_card_activation(
            order: spree_current_order,
            card_params: ts_card_params
          )
          render json: result.parsed_response, status: result.code || result["status"]
        end

        def ts_transaction_emails
          result = spo_checkout.ts_send_email(
            store: spree_current_store,
            emails_params: ts_emails_params
          )
          render json: result.parsed_response, status: result.code || result["status"]
        end
      
        private
        def render_ts_fullfilled
          render json: { "message" => "request already acknowledged", "status" => "completed"}, status: 200
        end

        def spo_checkout
          Spo::Checkout.new
        end

        def update_payment_transaction_meta
          order = Spree::Order.find_by(token: params[:order_token])
          return unless order
          payment = order.payments.last
          meta = payment.meta || {}
          meta = meta.merge(transaction_id: params["transaction_id"])
          payment.update(meta: meta)
        end

        def ts_emails_params
          params.permit(:recipient_emails, :transaction_id, :card_number)
        end

        def ts_card_params
          params.merge({store_name: spree_current_store.name, sku: params[:card_sku]})
            .permit(:store_name, :number, :allow_transaction_fee, :notes, :store_id, :order_number, :operator_id, :pin,
              :external_invoice_id, :amount, :currency, :ts_payment_method, :sku, :order_number, meta: {}, gift_card: {}, credential: {}, creator_attributes: {})
            
        end

        def line_item_options      
          { options: { sku: params[:sku] }, amount: params[:amount], customizations_attributes: { 
              name: "Serial Number", value: params[:serial_number] } }
        end

        def render_non_zero_cart
          render json: { "message" => Spree.t(:zero_cart_error), "status" => "completed"}, status: 200
        end

        def payment_cart_params
          { email: params[:email], state: :payment, ts_action: :ts_required }
        end

      end
    end
  end
end