module Spree
  module Api
    module V2
      module Storefront
        class PasswordsController < ::Spree::Api::V2::BaseController
          prepend Spree::ServiceModule::Base
          include Spree::Api::V2::CollectionOptionsHelpers
          skip_before_action :unauthorized_frontdesk_user

          def generate_reset_password_token
            is_vendor = false
            is_customer_support = false
            is_fulfilment_user = false
            if params[:vendor_portal].present?
              user = Spree::User.joins(:spree_roles).where("spree_roles.name IN  (?) AND email = ? AND store_id IS NULL", ['vendor','client','sub_client', 'front_desk', 'service_login_sub_admin', 'service_login_admin'], params[:email]).first
              is_vendor = true
            elsif params[:customer_support_portal].present?
              user = Spree::User.joins(:spree_roles).where("spree_roles.name =  ? AND email = ? AND store_id IS NULL", 'customer_support', params[:email]).first
              is_customer_support = true
            elsif params[:fulfilment_portal].present?
              user = Spree::User.joins(:spree_roles).where("spree_roles.name IN (?) AND email = ? AND store_id IS NULL", ['fulfilment_super_admin','fulfilment_admin','fulfilment_user'], params[:email]).first
              is_fulfilment_user = true
            else
              user = spree_current_store.users.find_by(email: params[:email])
            end
            if user.blank?
              render_error_payload(failure(user, "No user with this email").error)
            else
              raw, enc = Devise.token_generator.generate(Spree::User, :reset_password_token)
              user.reset_password_token   = enc
              user.reset_password_sent_at = Time.now.utc
              user.save(validate: false)

              if is_vendor == false && is_customer_support == false && is_fulfilment_user == false && spree_current_store&.ses_emails
                template = "customer_password_reset_store_" + ENV['SES_ENV'] + "_" + spree_current_store.id.to_s
                data = {"user_email" => params[:email], "password_reset_url" => spree_current_store.url + "/reset-password/" + raw}
                to_addresses = [params[:email]]
                from_address = spree_current_store&.mail_from_address
                SendSesEmailsWorker.perform_async(template, data, to_addresses, from_address)
              elsif is_customer_support == true
                Spree::PasswordMailer.send_reset_password_emil(spree_current_store, user.email, is_vendor , raw, is_customer_support).deliver_now
              elsif is_fulfilment_user == true
                Spree::PasswordMailer.send_reset_password_emil(spree_current_store, user.email, is_vendor , raw, is_customer_support, is_fulfilment_user).deliver_now
              else
                Spree::PasswordMailer.send_reset_password_emil(spree_current_store, user.email, is_vendor , raw, is_customer_support).deliver_now
              end
              render_serialized_payload { {success: true} }
            end
          end

          def create
            original_token = params[:reset_password_token]
            reset_password_token = Devise.token_generator.digest(Spree::User, :reset_password_token, original_token)
            user = Spree::User.where(reset_password_token: reset_password_token).first
            if user.blank?
              render_error_payload(failure(user, "No user with this email").error)
            else
              if user.reset_password_period_valid?
                if user.reset_password(params[:password], params[:password_confirmation])
                  render_serialized_payload { {success: true} }
                else
                  render_error_payload(failure(user).error)
                end
              else
                render_error_payload(failure(user, "Token is expireded").error)
              end
            end
          end
        end
      end
    end
  end
end
