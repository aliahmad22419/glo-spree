module Spree
  module Api
    module V2
      module Storefront
        class LalamovesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user

          def get_quotation
            options = {shipment_id: params[:shipment_id], scheduled_at: params[:scheduled_at]}
            result = Spree::Lalamove::Quotation.call(options: options)
            if result["success"]
              render json: result["value"]["data"].to_json, status: :ok
            else
              render json: result["value"]["errors"].to_json, status: :bad_request
            end
          end

          def place_order
            options = {shipment_id: params[:shipment_id], remarks: params[:remarks]}
            result = Spree::Lalamove::PlaceOrder.call(options: options)
            if result["success"]
              render json: result["value"]["data"].to_json, status: :ok
            else
              render json: result["value"]["errors"].to_json, status: :bad_request
            end
          end

          def cancel_order
            options = {shipment_id: params[:shipment_id]}
            result = Spree::Lalamove::CancelOrder.call(options: options)
            if result["success"]
              render json: result["value"]["data"].to_json, status: :ok
            else
              render json: result["value"]["errors"].to_json, status: :bad_request
            end
          end

        end
      end
    end
  end
end