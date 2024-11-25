module Spree
  module Api
    module V2
      module Storefront
        module ServiceLoginUser
          class AdminsController < ::Spree::Api::V2::BaseController
            before_action :require_spree_current_user
            before_action :set_service_login_user
            before_action :check_permissions

            def index
              service_login_sub_admin = Spree::ServiceLoginUser.ransack(params[:q]).result.distinct.order("created_at DESC")
              users = collection_paginator.new(service_login_sub_admin, params).call
              render_serialized_payload { serialize_collection(users) }
            end

            def update_password
              if @service_login_user.update(user_params)
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(@service_login_user).error)
              end
            end

            def profile
              render_serialized_payload { Spree::V2::Storefront::ServiceLoginUserSerializer.new(@service_login_user).serializable_hash }
            end

            def clients
              render json: {data: Spree::Client.select('id,name,email').order("id DESC")}, status: :ok
            end

            private

            def set_service_login_user
              @service_login_user = @spree_current_user.becomes(Spree::ServiceLoginUser)
            end

            def serialize_collection(collection)
              Spree::V2::Storefront::ServiceLoginUserSerializer.new(
                  collection,
                  collection_options(collection)
              ).serializable_hash
            end

            def user_params
              params.require(:user).permit(:password, :password_confirmation)
            end
          end
        end
      end
    end
  end
end
