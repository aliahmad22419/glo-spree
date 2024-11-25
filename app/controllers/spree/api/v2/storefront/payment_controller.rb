module Spree
    module Api
      module V2
        module Storefront
            class PaymentController < ::Spree::Api::V2::BaseController
              before_action :require_spree_current_user
              before_action :set_payment_method, only: [:show, :update, :destroy]
                def create
                  payment_method_params_hash = {public_key: params[:payment_method][:preferences][:public_key], api_username: params[:payment_method][:preferences][:api_username], api_password: params[:payment_method][:preferences][:api_password], merchant_account: params[:payment_method][:preferences][:merchant_account], live_url_prefix: params[:payment_method][:preferences][:live_url_prefix], ws_user: params[:payment_method][:preferences][:ws_user], ws_password: params[:payment_method][:preferences][:ws_password], api_key: params[:payment_method][:preferences][:api_key], server: params[:payment_method][:preferences][:server], test_mode: params[:payment_method][:preferences][:test_mode]}
                  if @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"client")
                    @payment_method = current_client.payment_methods.new(payment_params)
                    @payment_method.preferences =  payment_method_params_hash
                    
                    if @payment_method.save
                      render_serialized_payload { serialize_resource(@payment_method) }
                    else
                      render_error_payload(failure(@payment_method).error)
                    end
                  end
                end

                def update
                  payment_method_params_hash = {public_key: params[:public_key] , api_username: params[:api_username], api_password: params[:api_password], merchant_account: params[:merchant_account], live_url_prefix: params[:live_url_prefix], ws_user: params[:ws_user], ws_password: params[:ws_password], api_key: params[:api_key], server: params[:server], test_mode: params[:test_mode]}
                  if @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"client")
                    if @payment_method.update(payment_params)
                      @payment_method.preferences = payment_method_params_hash
                      @payment_method.save
                      render_serialized_payload { serialize_resource(@payment_method) }
                    else
                      render_error_payload(failure(@payment_method).error)
                    end
                  end
                end

                def show
                  render_serialized_payload { serialize_resource(@payment_method) }
                end

                def index
                  if @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"client")
                    payment_methods = current_client.payment_methods
                    render_serialized_payload { serialize_collection(payment_methods) }
                  end
                end

                private
                def set_payment_method
                  @payment_method = current_client.payment_methods.find_by('spree_payment_methods.id = ?', params[:id])
                end

                def payment_params
                  params.require(:payment_method).permit(:type, :display_on, :auto_capture, :active, :name, :description, :preferences)
                end
                
                def serialize_collection(collection)
                  Spree::V2::Storefront::PaymentMethodSerializer.new(
                      collection,
                      collection_options(collection)
                  ).serializable_hash
                end
      
                def serialize_resource(resource)
                  Spree::V2::Storefront::PaymentMethodSerializer.new(resource).serializable_hash
                end
          end
        end
    end
  end
end
  