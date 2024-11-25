module Spree
  module Api
    module V2
      module Storefront
        class FrontDeskCredentialsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_front_desk_credential, only: [:update_data, :get_data]
          skip_before_action :unauthorized_frontdesk_user

          def get_data
            @front_desk_credential = @front_desk_credential&.attributes&.merge(currency: get_front_desk_currency)
            render_serialized_payload { success(@front_desk_credential)&.value}
          end

          def update_data
            if @front_desk_credential
              if @front_desk_credential.update(front_desk_credential_params)
                render_serialized_payload { success(@front_desk_credential).value }
              else
                render_error_payload(failure(@front_desk_credential).error)
              end
            else
              front_desk_credential = FrontDeskCredential.new(front_desk_credential_params)
              front_desk_credential.user_id = @spree_current_user.id
              if front_desk_credential.save
                render_serialized_payload { success(front_desk_credential).value }
              else
                render_error_payload(failure(front_desk_credential).error)
              end
            end
          end

          def get_supported_currencies
            supported_currencies = @spree_current_user&.client&.supported_currencies
            data = { supported_currencies: supported_currencies }
            render json: data.to_json, status: :ok
          end

          private
          # Use callbacks to share common setup or constraints between actions.
          def set_front_desk_credential
            @front_desk_credential = @spree_current_user&.front_desk_credential
          end

          # Never trust parameters from the scary internet, only allow the white list through.
          def front_desk_credential_params
            params[:front_desk_credential].permit(:tsgifts_email, :tsgifts_password, :tsgifts_url, :tsdefault_currency)
          end

          def get_front_desk_currency
            return (::Money::Currency.table.uniq {|c| c[1][:iso_code]}.map do |_code, details|
              iso = details[:iso_code]
              [iso, "#{details[:name]} (#{iso})"]
            end)
          end 
        end


      end
    end
  end
end
