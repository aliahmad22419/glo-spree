module Spree
  module V2
    module Storefront
      class VendorSerializer < BaseSerializer
        set_type :vendor
        set_key_transform :camel_lower # "some_key" => "someKey"

        attributes :name, :contact_name, :enabled, :external_vendor, :page_enabled, :phone, :vacation_start, :vacation_end, :banner_image, :conf_contact_name,
                   :landing_page_title, :enabled_google_analytics, :google_analytics_account_number, :description, :sku, :created_at,
                   :landing_page_url, :additional_emails, :state, :designer_text, :slug, :banner_image_id,
                   :local_store_ids, :vacation_mode, :sales_report_password, :agreed_to_client_terms, :about_us

        attribute :email, &:email

        attribute :users do |object, params|
          Spree::V2::Storefront::UserSerializer.new(object.users,  params: params
          ).serializable_hash
        end

        attribute :stores do |object, params|
          if params[:allow_store_ids].present?
            object.client.stores.select("id, name").where(id: params[:allow_store_ids])
          else
            object.client.stores.select("id, name")
          end
        end

        attribute :vendor_group do |object|
          object.vendor_group
        end

        # attribute :enable_mov do |object|
        #   object.client.enable_mov
        # end

        attribute :adyen_account do |object|
          object.adyen_account
        end

        attribute :adyen_account_verification do |object|
          # object.adyen_account&.get_account_holder
          nil
        end

        attribute :parameterize_name do |object|
          object.name.parameterize
        end


        attribute :microsite do |object|
          object.microsite.to_s
        end

        attribute :image do |object|
          Spree::V2::Storefront::ImageSerializer.new(Spree::Image.where(id: object.image_id).first).serializable_hash
        end

        attribute :banner_image do |object|
          img = Spree::Image.where(id: object.banner_image_id).first
          img&.active_storge_url(img&.attachment)
        end

        attribute :client_image do |object|
          object&.client&.active_storge_url(object&.client&.logo)
        end

        attribute :billing_address do |object|
          Spree::V2::Storefront::AddressSerializer.new(object.billing_address).serializable_hash
        end

        attribute :shipping_address do |object|
          Spree::V2::Storefront::AddressSerializer.new(object.shipping_address).serializable_hash
        end

        attribute :brand_follow_data do |object, params|
          vendor_user = object&.users&.first
          data = {vendor_user_id: '', brand_followed: false, follow_request_approved: false}
          if vendor_user.present?
            data['vendor_user_id'] = vendor_user.id
            if params[:followee_user_id].present?
              data['brand_followed'] = true if vendor_user.followed_users.pluck(:followee_id).include?(params[:followee_user_id])
              data['follow_request_approved'] = true if vendor_user.followed_users.approved.pluck(:followee_id).include?(params[:followee_user_id])
            end
          end
          data
        end

        attribute :base_currncy do |object|
          object&.base_currency&.name
        end

        attribute :preferences do |object|
          object.client.preferences.slice(:vendor_agreement_text)
        end


      end
    end
  end
end
