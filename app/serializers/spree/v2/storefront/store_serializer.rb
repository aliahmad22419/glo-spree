module Spree
  module V2
    module Storefront
      class StoreSerializer < BaseSerializer
        set_type :store

        attributes :name, :url, :meta_description, :meta_keywords, :seo_title, :mail_from_address, :code, :sabre_reference_code, :recipient_emails, :google_translator, :timezone_list,
                   :ask_seller, :vendor_visibility, :mailchip, :default_currency, :fb_username, :insta_username, :twitter_username, :included_tax_label, :excluded_tax_label, :truncated_text_length,
                   :pinterest_username, :linkedin_username, :gtm_tags, :description, :recaptcha_key, :country_specific, :refunds_timeline, :subscription_title, :subscription_text,
                   :page_title, :copy_rights_text, :top_category_url_to_product_listing, :carosel_spacing, :max_image_width, :max_image_height,
                   :show_ship_countries, :adyen_origin_key, :ship_to_label, :bcc_emails, :ses_emails , :per_page, :download_order_details, :default_tax_zone_id,
                   :enable_client_default_tax, :default_url, :acm_arn, :enable_review_io, :reviews_io_api_key, :reviews_io_store_id, :reviews_io_bcc_email,
                   :givex_user, :givex_password, :givex_url, :givex_secondary_url, :enable_finance_report, :finance_report_to, :finance_report_cc, :hawk_username, :hawk_password, :hawk_store_channel_code,
                   :hawk_api_url, :ts_gift_card_email, :ts_gift_card_password, :ts_gift_card_url, :swatches, :is_show_swatches, :line_username,
                   :enable_checkout_terms, :checkout_terms, :enable_marketing, :marketing_statement, :is_www_domain, :google_site_verification_tag, :burger_menu_theme,
                   :contact_number, :mail_to, :customer_service_url, :decimal_points, :currency_formatter, :lalamove_url, :lalamove_market, :lalamove_pk, :lalamove_sk, :sales_report_password, :schedule_report,
                   :min_custom_price, :max_custom_price, :checkout_flow, :preferences, :max_cart_transaction, :supported_currencies, :show_brand_name,
                   :stripe_standard_account_id, :stripe_express_account_id, :scheduled_reports, :v3_flow_address, :enable_v3_billing, :note, :fulfilment_start_date, :allow_fulfilment, :test_mode,
                   :hcaptcha_key, :client_id, :prefix, :suffix

        attribute :shipping_method_ids do |object|
	        object.shipping_method_ids.map{|id| id.to_s}
        end

        attribute :lalamove_pickup_order_tag_id do |object|
	        object.lalamove_pickup_order_tag_id&.to_s
        end

        attribute :lalamove_complete_order_tag_id do |object|
          object.lalamove_complete_order_tag_id&.to_s
        end

        attribute :payment_methods do |object|
	        object.client.payment_methods.active.select(:id, :name, :payment_options)
        end

        attribute :selected_payment_methods do |object|
          selected_pms = []
          object.store_payment_methods.group_by(&:payment_method_id).each do |pm_id, store_payment_methods|
            opts = []
            store_payment_methods.each{|m| opts << { payment_option: m.payment_option, payment_option_display: m.payment_option_display, apple_pay_domains: m.apple_pay_domains }}
            payment_method = object.payment_methods.select(:name,:id,:type,:preferences, :payment_option).find(pm_id) if object&.payment_methods.any?
            selected_pms << { payment_method_id: pm_id, store_id: object.id, payment_options: opts, payment_method: payment_method, payment_method_type: payment_method&.type }
          end
          selected_pms
        end

        attribute :country_ids do |object|
          object&.country_ids&.map{|id| id.to_s}
        end

        attribute :zone_ids do |object|
          object&.zone_ids&.map{|id| id.to_s}
        end

        attribute :layout_settings do |object|
	        object.layout_setting&.preferences
        end

        attribute :email_configurations do |object|
          object.email_notification_configuration&.preferences
        end

        attribute :gift_card_pdf do |object|
          object.gift_card_pdf&.preferences
        end

        attribute :invoice_configurations do |object|
          image_url = object&.invoice_configuration&.active_storge_url(object&.invoice_configuration&.image)
          object&.invoice_configuration&.attributes&.slice('id', 'brand', 'address', 'phone', 'email', 'notes', 'store_id')&.merge({ image_url: image_url, image: object&.invoice_configuration&.image&.filename })
        end

        attribute :mailchimp_setting do |object|
	        object.mailchimp_setting
        end

        attribute :pickup_address do |object|
          object.pickup_address
        end

        attribute :general_settings do |object|
	         (object.general_settings || {})
        end

        attribute :classifications do |object, params|
          data = object&.classifications&.group_by(&:taxon_id) || []
          data_hash = {}
          data.each do |taxon, c_data|
            data_hash[taxon] = []
            c_data.each do |c|
              data_hash[taxon] << c.position
            end
          end
          data_hash
        end

        # attribute :cnames do |object|
        #   object.acm_cnames
        # end

        attribute :has_stripe_connected_account do |object|
          object.send(:stripe_connected_account).present?
        end

        attribute :stripe_connected_account do |object|
          {
            express: object.stripe_express_account_id.presence,
            standard: object.stripe_standard_account_id.presence
          }
        end

        attribute :stripe_keys do |object|
          stripe_payment_method = object.payment_methods.active_with_type('Spree::Gateway::StripeGateway')[0]
          (stripe_payment_method.present? ? stripe_payment_method.preferences.slice(:client_key) : { client_key: '' })
        end

        attribute :stripe_secret_keys do |object, params|
          if params[:user].present? && params[:user].has_access_to_home?
            stripe_payment_method = object.payment_methods.active_with_type('Spree::Gateway::StripeGateway')[0]
            { stripe_secret_key: stripe_payment_method&.preferred_secret_key, stripe_connected_account_id: object.send(:stripe_connected_account) }
          else
            { stripe_secret_key: nil, stripe_connected_account_id: nil }
          end
        end

        attribute :passbook do |object|
          pass = (object.apple_passbook.present? ? object.apple_passbook.attributes.except("created_at", "updated_at") : {})
          pass.merge!({ certificate: (object.passbook_certificate.attached? ? object.passbook_certificate.filename : nil) })
          pass
        end
      end
    end
  end
end
