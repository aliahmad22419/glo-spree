module Spree
  module Api
    module V2
      module Storefront
        module ServiceLoginUser
          class SubAdminsController < ::Spree::Api::V2::BaseController
            before_action :require_spree_current_user
            before_action :set_service_login_user
            before_action :check_permissions
            before_action :set_user, only: [:update, :show, :destroy]
            before_action :set_archive_users, only: [:destroy_multiple, :reinstate]

            def show
              render_serialized_payload { Spree::V2::Storefront::ServiceLoginUserSerializer.new(@user).serializable_hash }
            end

            def create
              user = Spree::ServiceLoginUser.new(user_params)
              role = Spree::Role.find_by_name "service_login_sub_admin"
              user.spree_roles << role
              if user.save
                render_serialized_payload { Spree::V2::Storefront::ServiceLoginUserSerializer.new(user).serializable_hash }
              else
                render_error_payload(user.errors.full_messages[0], 403)
              end
            end

            def update
              if @user.update(user_params)
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(@user).error)
              end
            end

            def reinstate
              if @archive_users.update_all(is_enabled: true)
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(@archive_users).error)
              end
            end

            def destroy_multiple
              if @archive_users.destroy_all
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(@archive_users).error)
              end
            rescue Exception => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            def destroy
              return render json: {error: "Active User can't be deleted."}, status: 403  if @user.is_enabled
              if @user.destroy
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(@user).error)
              end
            end

            def clients
              render json: {data: @service_login_user.clients.select('spree_clients.id,spree_clients.name,spree_clients.email')}, status: :ok
            end

            def authenticate_sub_client
              client = @service_login_user&.clients.find_by('spree_clients.id = ?', params[:client_id])
              return render json: {error: "You don't have access to this client"}, status: 403 unless client
              sub_client = client.users.with_role_all("sub_client").find_by(service_login_user_id: @service_login_user.id)
              return render_error_payload("This user is not assigned to any sub user of this client.", 404) unless sub_client

              new_doorkeeper_user = bypass_serivce_login_sub_admin(sub_client)
              if new_doorkeeper_user
                doorkeeper_token.revoke
                render json: { data: new_doorkeeper_user}, status: 200
              else
                render json: { error: 'Invalid Authentication' }, status: :unauthorized
              end
            end


            private

            def bypass_serivce_login_sub_admin(user)
              token = Spree::OauthAccessToken.create!(
                resource_owner_id: user.id,
                expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
                resource_owner_type: 'Spree::User',
                scopes: ''
              )
              response = {
                "access_token": token.token,
                "token_type": "Bearer",
                "expires_in": token.expires_in,
                "id": user.id,
                "message": "Please update your app"
              }
              response.merge(Spree::User.custom_response_variables(token))
            end

            def set_user
              @user = Spree::ServiceLoginUser.find_by('spree_users.id = ?', params[:id])
              return render json: {error: "User not found"}, status: 403 unless @user
            end

            def set_archive_users
              @archive_users = Spree::ServiceLoginUser.archive_service_login_users.where(id: JSON.parse(params[:ids]))
              return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @archive_users&.any?
            end

            def set_service_login_user
              @service_login_user = @spree_current_user.becomes(Spree::ServiceLoginUser)
            end

            def user_params
              params.require(:user).permit(:name, :email, :password, :password_confirmation, :is_enabled, client_ids: [])
            end
          end
        end
      end
    end
  end
end
