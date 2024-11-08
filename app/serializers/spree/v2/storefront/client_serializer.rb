module Spree
  module V2
    module Storefront
      class ClientSerializer < BaseSerializer
        set_type :client
        set_key_transform :camel_lower # "some_key" => "someKey"
        attributes :name, :email, :supported_currencies, :stipe_connected_account_id, :number_of_images,
                   :product_validations, :auto_approve_products, :already_selling, :current_revenue, :type_of_industry,
                   :selling_platform, :multi_vendor_store, :business_name, :skill_level, :product_type, :client_address_id,
                   :client_address, :reporting_currency, :ts_email, :ts_password, :ts_url, :sales_report_password, :from_phone_number,
                   :customer_support_email, :show_gift_card_number, :show_all_gift_card_digits, :timezone, :reporting_from_email_address, :preferences

        attribute :assigned_base_currencies do |object|
          Spree::Currency.where(vendor_id: object.vendors.ids).pluck(:name).uniq.compact
        end

        attribute :user_email do |object|
          object.users.last&.email
        end

        attribute :assigned_store_default_currencies do |object|
          object.stores.pluck(:supported_currencies).flatten.uniq.compact
        end

        attribute :embeded_widgets do |object|
          object&.embed_widgets&.select("id, site_domain")
        end

        attribute :zone_based_stores do |object|
          object.zone_based_stores.to_s
        end

        attribute :allow_brand_follow do |object|
          object.allow_brand_follow.to_s
        end

        attribute :tax_categories do |object|
          object.tax_categories
        end

        attribute :vendors do |object|
          object.vendors.approved_vendors.order(name: :asc)
        end

        attribute :ts_reports_password do |object|
          object.sales_report_password.presence || ENV['ZIP_ENCRYPTION']
        end

        attribute :default_reports_password do |object|
          ENV['ZIP_ENCRYPTION']
        end

        attribute :stripe_statement_descriptor_suffix do |object|          
          object&.stores&.first&.preferences[:stripe_statement_descriptor_suffix]
        end
      end
    end
  end
end
