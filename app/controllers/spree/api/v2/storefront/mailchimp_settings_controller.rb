module Spree
  module Api
    module V2
      module Storefront
        class MailchimpSettingsController < ::Spree::Api::V2::BaseController
          # class MailchimpSettingsController < ResourceController
          before_action :require_spree_current_client
          before_action :set_store, only: [:create, :update]
          # def index
          #   path = model_class.first ? edit_admin_mailchimp_setting_path(model_class.first.id) : new_admin_mailchimp_setting_path
          #   redirect_to path
          # end

          def create
            mailchimp_setting_attributes
            if @mailchimp_setting.save
              begin
                ::SpreeMailchimpEcommerce::CreateStoreJob.perform_now(@mailchimp_setting) unless @mailchimp_setting.already_exist?
                ::SpreeMailchimpEcommerce::UploadStoreContentJob.perform_later(@mailchimp_setting)
                @mailchimp_setting.update(mailchimp_account_name: @mailchimp_setting.accout_name)
                render_serialized_payload { serialize_resource(@store) }
              rescue Gibbon::MailChimpError => e
                render_error_payload(e.detail, 404) and return
              end
            else
              render_error_payload(@mailchimp_setting.errors.full_messages[0], 501) and return
            end
          end

          def update
            @mailchimp_setting = @store.mailchimp_setting
            ActiveRecord::Base.transaction do
              if update_without_api_key?
                @mailchimp_setting.update(permitted_params)
                ::SpreeMailchimpEcommerce::UpdateStoreJob.perform_later(@mailchimp_setting)
              end
            end
            render_serialized_payload { serialize_resource(@store) } and return
          end

          # def destroy
          #   @mailchimp_setting = MailchimpSetting.find(params[:id])
          #   ActiveRecord::Base.transaction do
          #     ::SpreeMailchimpEcommerce::DeleteStoreJob.perform_now({"store_id" => params[:store_id]})
          #     @mailchimp_setting.destroy
          #   end
          #   redirect_to new_admin_mailchimp_setting_path
          # end

          private

          def serialize_resource(resource)
            Spree::V2::Storefront::StoreSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_store
             @store = current_client.stores.find_by('spree_stores.id = ?', params[:my_store_id])
          end

          def model_class
            @model_class ||= ::MailchimpSetting
          end

          def permitted_params
            params.require(:mailchimp_setting).permit(:mailchimp_api_key, :mailchimp_list_id, :mailchimp_store_name, :mailchimp_store_email, :mailchimp_url)
          end

          def update_without_api_key?
            api_key = @mailchimp_setting.mailchimp_api_key
            list_id = @mailchimp_setting.mailchimp_list_id
            @mailchimp_setting.multi_store = true
            same_keys = api_key.eql?(permitted_params["mailchimp_api_key"]) && list_id.eql?(permitted_params["mailchimp_list_id"])
            unless same_keys
              ::SpreeMailchimpEcommerce::DeleteStoreJob.perform_now({ store_id: @mailchimp_setting.store_id }) unless @mailchimp_setting.already_exist?
              @store.mailchimp_setting.destroy
              @store.reload
              mailchimp_setting_attributes
              if @mailchimp_setting.save
                begin
                  ::SpreeMailchimpEcommerce::CreateStoreJob.perform_now(@mailchimp_setting) unless @mailchimp_setting.already_exist?
                  ::SpreeMailchimpEcommerce::UploadStoreContentJob.perform_later(@mailchimp_setting)
                  @mailchimp_setting.update(mailchimp_account_name: @mailchimp_setting.accout_name)
                rescue Gibbon::MailChimpError => e
                  render_error_payload(e.detail, 404) and return
                end
              end
            end
            same_keys
          end

          def mailchimp_setting_attributes
            @mailchimp_setting = @store.mailchimp_setting
            @mailchimp_setting ||= @store.build_mailchimp_setting(permitted_params)
            @mailchimp_setting.mailchimp_store_id = @mailchimp_setting.create_store_id
            @mailchimp_setting.multi_store = true
            @mailchimp_setting.cart_url = "#{@store.url}/cart"
          end
        end
      end
    end
  end
end
