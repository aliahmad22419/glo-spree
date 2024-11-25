module Spree
  module Api
    module V2
      module Storefront
        class WhitelistEmailsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :require_spree_current_client
          before_action :check_permissions
          before_action :set_whitelist_email, only: [:resend_verification, :destroy, :retry_domain_verification, :show]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            whitelist_emails = current_client.whitelist_emails.ransack(params[:q]).result.order("created_at DESC")
            whitelist_emails = collection_paginator.new(whitelist_emails, params).call
            render_serialized_payload { serialize_collection(whitelist_emails) }
          end
        
          def create
            @whitelist_email = current_client.whitelist_emails.new(whitelist_email_params.merge({user_id: @spree_current_user.id, service_type: 'SES'}))
            if @whitelist_email.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@whitelist_email).error)
            end
          end

          def show
            render_serialized_payload { serialize_resource(@whitelist_email) }
          end

          def resend_verification
            return render json: { error: "Unable to resend for #{@whitelist_email.status} email" }, status: 422 unless @whitelist_email.failed?
            
            @whitelist_email.resend_verification
            render_serialized_payload { success({success: true}).value }
          end

          def retry_domain_verification
            return render json: { error: "Unable to retry for #{@whitelist_email.status} domain" }, status: 422 if @whitelist_email.verified?

            @whitelist_email.retry_domain_verification
            render_serialized_payload { success({success: true}).value }
          end
        
          def destroy
            if @whitelist_email.destroy
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@whitelist_email).error)
            end
          end
        
          private

          def serialize_resource(resource)
            Spree::V2::Storefront::WhitelistEmailSerializer.new(resource).serializable_hash
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::WhitelistEmailSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def set_whitelist_email
            @whitelist_email = current_client.whitelist_emails.find_by('spree_whitelist_emails.id = ?', params[:id])
            return render json: { error: "Resource you are looking for could not be found" }, status: :not_found unless @whitelist_email.present?
          end
        
          def whitelist_email_params
            params.require(:whitelist_email).permit(:email, :domain, :identity_type, :recipient_email)
          end

        end
      end
    end    
  end
end
