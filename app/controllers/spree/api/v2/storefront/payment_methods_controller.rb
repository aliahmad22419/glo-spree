module Spree
  module Api
    module V2
      module Storefront
        class PaymentMethodsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_payment_method, only: [:show, :update, :destroy]
					before_action :check_permissions
          before_action :authorized_client_sub_client, only: [:create, :update]

          def create
            params[:payment_method][:preferences].permit!
            preferences = params[:payment_method][:preferences].to_h.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
            @payment_method = current_client.payment_methods.new(payment_params)
            @payment_method.preferences = preferences

            if @payment_method.save
              render_serialized_payload { serialize_resource(@payment_method) }
            else
              render_error_payload(failure(@payment_method).error)
            end
          end

          def update
            params[:payment_method][:preferences].permit!
            preferences = params[:payment_method][:preferences].to_h.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
            params[:payment_method].delete(:preferences)
            @payment_method.preferences = preferences

            if @payment_method.update(payment_params)
              render_serialized_payload { serialize_resource(@payment_method) }
            else
              render_error_payload(failure(@payment_method).error)
            end
          end

          def show
            render_serialized_payload { serialize_resource(@payment_method) }
          end

          def index
            payment_methods = Spree::PaymentMethod.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
            payment_methods = collection_paginator.new(payment_methods, params).call
            render_serialized_payload { serialize_collection(payment_methods) }
          end

          private

          def set_payment_method
            @payment_method = current_client.payment_methods.find_by('spree_payment_methods.id = ?', params[:id])
            return render json: { error: "Payment Method not found" }, status: 403 unless @payment_method
          end

          def payment_params
            params.require(:payment_method).permit(:type, :display_on, :auto_capture, :active, :name, :description, :preferences, payment_options: [])
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::PaymentMethodSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::PaymentMethodSerializer.new(resource, params: {user: @spree_current_user}).serializable_hash
          end
        end
      end
    end
  end
end
  