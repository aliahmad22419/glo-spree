module Spree
  module Api
    module V2
      module Storefront
        class ShipmentsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, only: [:index]
          before_action :set_shipment, only: [:update]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            params[:q] = {} if params[:q].blank?
            params[:q][:delivery_pickup_date_not_null] = true
            params[:q][:delivery_pickup_time_not_eq] = ""
            params[:q][:delivery_pickup_date_gteq] = Date.today

            if @spree_current_user.spree_roles.map(&:name).include?"vendor"
              vendor = @spree_current_user.vendors.first
              params[:q][:vendor_id_eq] = vendor.id
            elsif (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              params[:q][:vendor_id_in] = @spree_current_user&.client&.vendor_ids
            end
              shipments = Spree::Shipment.ransack(params[:q]).result(distinct: true).order("delivery_pickup_date ASC")
              shipments = collection_paginator.new(shipments, params).call
              render_serialized_payload { serialize_collection(shipments) }
          end

          def update
            @shipment.delivery_pickup_date_zone = DateTime.parse(params[:shipment][:delivery_pickup_date]).zone if params[:shipment][:delivery_pickup_date].present?
            if @shipment.update(shipment_params)
              render json: { success: true, updated_at: @shipment.reload.order.updated_at }, status: 200
            else
              render_error_payload(failure(@shipment).error)
            end
          end

          def update_status_with_lalamove
            MarkOrderWithLalamoveStatusWorker.perform_async(params.to_json)
            render json: {}, status: 200
          end

          private

            def set_shipment
              @shipment = Shipment.find_by('spree_shipments.id = ?', params[:id])
            end

            def shipment_params
              params[:shipment].permit(:delivery_type,
                                      :delivery_pickup_date,
                                      :delivery_pickup_time,
                                      :delivery_pickup_date_zone,
                                      :card_generation_datetime
                                     )
            end

            def serialize_collection(collection)
              Spree::V2::Storefront::ShipmentSerializer.new(
                collection,
                collection_options(collection)
              ).serializable_hash
            end
        end
      end
    end
  end
end
