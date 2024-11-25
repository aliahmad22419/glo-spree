module Spree
  module EghlConcern
    def self.included(base)
      base.class_eval do
        before_action :ensure_order, except: [:response_eghl, :response_eghl_call_back, :redirect_front_end]
        before_action :ensure_eghl_data, only: [:response_eghl, :response_eghl_call_back, :redirect_front_end]

        def redirect_front_end
          redirect_to "#{@spree_current_store&.subfoldering_url}/checkout?redirect_front_end=true"
        end
      
        def response_eghl
          redirect_to "#{@spree_current_store&.subfoldering_url}/checkout?payment_failed=true" and return if @request_params["TxnStatus"] == "1"

          if @request_params["TxnStatus"] == "0"
            if @order.payments.last&.state != "completed"
              params_hash = {"apply_giftcard"=>false, "order"=>{"payments_attributes"=>[{"amount" => BigDecimal(@order.price_values[:prices][:payable_amount]), "payment_method_id"=>@eghl_params["payment_method_id"].first, "source_attributes"=>{"gateway_payment_profile_id"=>@request_params["TxnID"], "cc_type"=>"EGHL"}}]}}                

              result = update_service.call(
                order: @order,
                params: ActionController::Parameters.new(params_hash),
                permitted_attributes: permitted_checkout_attributes,
                request_env: request.headers.env
              )
      
              @order.payments.checkout.each(&:complete!)
              @order.update(state: "confirm")
            end
            redirect_to "#{@spree_current_store&.subfoldering_url}/checkout/complete"
          end
        end

        def response_eghl_call_back
          if @request_params["TxnStatus"] == "0"
            params_hash = {"apply_giftcard"=>false, "order"=>{"payments_attributes"=>[{"payment_method_id"=>@eghl_params["payment_method_id"].first, "source_attributes"=>{"gateway_payment_profile_id"=>@request_params["TxnID"], "cc_type"=>"EGHL"}}]}}
      
            result = update_service.call(
              order: @order,
              params: ActionController::Parameters.new(params_hash),
              permitted_attributes: permitted_checkout_attributes,
              request_env: request.headers.env
            )
      
            @order.payments.checkout.each(&:complete!)
            render json: { message: "ok" }, status: :ok
          end
        end

        def ensure_eghl_data
          if (request.params["Param6"].present?)
            @request_params = request.params
            @eghl_params = CGI::parse(@request_params["Param6"])
            @order = Spree::Order.find_by(token: @eghl_params["orderToken"].first)
            render_error_payload("Order not found", 400) and return if @order.blank?
            @order.send(:cancel_stripe_payment)
            @spree_current_store = Spree::Store.find_by('spree_stores.id = ?', @eghl_params["storeId"].first)
          else
            render_error_payload("Unprocessable request", 400)
          end
        end
      end
    end
  end
end
