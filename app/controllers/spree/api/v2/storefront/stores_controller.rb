module Spree
  module Api
    module V2
      module Storefront
        class StoresController < ::Spree::Api::V2::BaseController
          include CustomCssHelper
          before_action :require_spree_current_user, :if => Proc.new{ params[:access_token] }
          before_action :check_permissions
          before_action :store_or_client_not_found, except: [:is_new_store, :all_stores, :sales_report]
          before_action :set_store, only: [:send_dns_details, :set_iframe_store_layout_preferences, :iframe_store_layout_settings, :update_apple_passbook, :stripe_dashboard, :update_strip_info, :update_payment_methods, :update_pickup_address, :update_v3_flow_address, :general_settings, :email_configurations, :gift_card_pdf, :layout_settings, :show, :update, :destroy_logo, :get_styling, :get_javacript, :publish, :publish_html_layouts, :copy_version, :get_acm_certificate, :regenerate_dns, :invoice_configurations, :load_balancer_ssl_setup_alert]
          before_action :check_domain_availability, only: [:create]
          before_action :preferred_layout, only: [:layout_settings]
          before_action :preferred_email_config, only: [:email_configurations]
          before_action :preferred_gift_card_config, only: [:gift_card_pdf]
          before_action :set_settings, only: [:general_settings]
          before_action :set_layout, only: [:publish, :copy_version]
          before_action :preferred_invoice_config, only: [:invoice_configurations]
          before_action :authorized_client_sub_client, only: [:client_stores]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if current_client.present?
              stores = Spree::Store.accessible_by(current_ability, :index).ransack(params[:q]).result
              stores = collection_paginator.new(stores, params).call if params[:page].present? && params[:per_page].present?
            else
              stores = storefront_current_client.stores
            end
            render_serialized_payload { serialize_store_collection(stores) }
          end

          def all_stores
            stores = Spree::Store.select('id, name').order('LOWER(name)').live_store
            render json: stores, status: 200
          end

          def show
            render_serialized_payload { serialize_resource(@store) }
          end

          def update
            render_error_payload("Store not found",404) and return unless @store
            @store.update_preferences(params[:store][:preferences]) if params[:store][:preferences]
            if @store.update(store_params)
              render_serialized_payload { serialize_resource(@store) }
            else
              render_error_payload(failure(@store).error)
            end
          end

          def update_pickup_address
            params[:pickup_address].permit!
            pickup_address = @store.pickup_address
            pickup_address = @store.build_pickup_address if pickup_address.blank?
            pickup_address.attributes = params[:pickup_address]
            pickup_address.save(validate: false)
            @store.pickup_address_id = pickup_address.id
            if @store.save(validate: false)
              render_serialized_payload {  {result: true}  }
            else
              render_error_payload(failure(@store).error)
            end
          end

          def update_v3_flow_address
            params[:v3_flow_address].permit!
            address = @store.v3_flow_address
            address = @store.build_v3_flow_address if address.blank?
            address.attributes = params[:v3_flow_address]
            if address.save(validate: false)
              @store.update_column(:v3_flow_address_id, address.id)
              render_serialized_payload { {result: true} }
            else
              render_error_payload(failure(address).error)
            end
          end

          def update_payment_methods
            render_error_payload("Payment Methods cannot be blank") and return unless params[:store_payment_methods].present?

            @store.store_payment_methods.destroy_all
            params[:store_payment_methods].each do |store_pm_attrs|
              store_pm_attrs[:payment_options].each do |popt|
                apple_pay_domains = is_stripe_ePays?(popt, store_pm_attrs) ? @store.register_stripe_apple_pay_domain(store_pm_attrs) : "empty"
                store_pm = @store.store_payment_methods.find_or_initialize_by(
                  payment_method_id: store_pm_attrs[:payment_method_id],
                  payment_option: popt[:payment_option]
                )
                store_pm.apple_pay_domains =  apple_pay_domains
                store_pm.payment_option_display = popt[:payment_option_display]
              end
            end
            render_serialized_payload { serialize_resource(@store) } if @store.save!
          end

          def create
            store = current_client.stores.new(store_params)
            store.new_layout = true
            if store.save
              store.update_preferences(params[:store][:preferences]) if params[:store][:preferences]
              render_serialized_payload { serialize_resource(store) }
            else
              render_error_payload(failure(store).error)
            end
          end

          def create_store_onboarding
            store = current_client.stores.find_by('spree_stores.id = ?', params[:id])
            if store.update(store_params)
              store.update_preferences(params[:store][:preferences])
              current_client.zones.create(name: store.name.parameterize, country_ids: store.country_ids)
              render_serialized_payload { serialize_resource(store) }
            else
              render_error_payload(failure(store).error)
            end
          end

          def layout_settings
            @layout_setting.update_preferences(params[:settings])

            if @layout_setting.save
              render_serialized_payload { serialize_resource(@layout_setting.store) }
            else
              render_error_payload(@layout_setting.errors.full_messages[0], 403)
            end
          end

          def iframe_store_layout_settings
            begin
              update_iframe_store_image if params[:settings][:imageId].present?
              set_iframe_store_layout_preferences
            rescue StandardError => e
              render_error_payload(e)
            end
          end

          def get_iframe_store_layout_settings
            store = current_client&.stores&.first
            layout_setting = Spree::LayoutSetting.find_by_store_id(store&.id)
            store_logo = store&.html_page&.html_layout&.html_components&.first&.html_ui_blocks&.first&.image&.attachment        
            render json: {layout_setting: layout_setting, store_logo: store_logo, store_id: store&.id, store_name: store&.name, product_slug: store&.products&.first&.slug, client_id: store&.client&.id, has_stripe_connected_account: store.send(:stripe_connected_account).present?}, status: :ok
          end
                
          def update_iframe_store_image
            begin
              @store.update_store_image(params[:settings][:imageId])
            rescue StandardError => e
              raise
            end
          end

          def set_iframe_store_layout_preferences
            begin
              layout_setting = Spree::LayoutSetting.find_or_create_by(store_id: @store.id)
              if layout_setting.update_preferences(params[:settings])
                render json: {layout_setting: layout_setting, store_url: "https://#{@store.default_url}/#{@store&.products&.first&.slug}"}, status: :ok
              else
                render_error_payload(layout_setting.errors.full_messages.first, :forbidden)
              end
            rescue StandardError => e
                raise
            end
          end
          
          def email_configurations
            @email_config.update_preferences(params[:configs])

            if @email_config.save
              render_serialized_payload { serialize_resource(@email_config.store) }
            else
              render_error_payload(@email_config.errors.full_messages[0], 403)
            end
          end

          def gift_card_pdf
            @gift_card_config.update_preferences(params[:pdf_configs])

            if @gift_card_config.save
              render_serialized_payload { serialize_resource(@gift_card_config.store) }
            else
              render_error_payload(@gift_card_config.errors.full_messages[0], 403)
            end
          end

          def invoice_configurations
            @invoice.image.attach(params[:image]) if params[:image].present?
            if @invoice.update(invoice_params)
              render_serialized_payload { serialize_resource(@invoice.store) }
            else
              render_error_payload(@invoice.error.full_messages[0], 403)
            end
          end

          def general_settings
            @settings.update_preferences(params[:settings])

            if @settings.save
              render_serialized_payload { serialize_resource(@settings.store) }
            else
              render_error_payload(@settings.errors.full_messages[0], 403)
            end
          end

          def destroy
            render_error_payload("Store cannot be deleted.",403)

            # # Before uncommenting below code make sure to add destroy method in set_store before_action callback above
            # # --------------------------------------------------------------------------------------------------------
            # render_error_payload("Store not found",404) and return unless @store
            # if @store.destroy
            #   render_serialized_payload { serialize_resource(@store) }
            # else
            #   render_error_payload(failure(@store).error)
            # end
          end

          def publish_html_layouts
            publish_html_layouts = @store.html_page.publish_html_layouts.order(created_at: :desc)
            render json: publish_html_layouts.to_json
          end

          def update_strip_info
            result = @store.authorize_for_stripe(params[:code], params[:account_type])
            if result[:response_result]
              render_serialized_payload { {success: true} }
            else
              render json: { error: result[:strip_error] }, status: (result[:status] || 400)
            end
          end

          def stripe_dashboard
            stripe_payment_method = @store.payment_methods.active_with_type('Spree::Gateway::StripeGateway')[0]
            stripe_account_id = @store.stripe_express_account_id

            render_error_payload(I18n.t("stripe.error.connected_account.blank"), 404) and
              return if stripe_payment_method.blank? || stripe_account_id.blank?

            Stripe.api_key = stripe_payment_method.preferred_secret_key
            login_link = Stripe::Account.create_login_link(stripe_account_id)
            render json: { link: login_link }, status: 200
          end

          def publish
            if @layout.publish
              render json: {success: "Nothing to Publish.Everything is update to date"}
            else
              Store.transaction do
                @store.html_page.publish_html_layouts&.update_all(active: false)
                @store.update_column(:new_layout, true)
                PageBuilderWorker.perform_async(@store.html_page.id, @layout.id, true)
                render json: {success: "Your request is in progress."}
              end
            end
          end

          def is_new_store
            if params[:store_name].present?
              store_name = params[:store_name].downcase
              if Spree::Store.joins(:translations).where("LOWER(spree_store_translations.name) = ?", store_name).present?
                render_serialized_payload { {result: false} }
              else
                render_serialized_payload { {result: true} }
              end
            end
          end

          def copy_version
            publish_layout = @store&.html_page.publish_html_layouts.find_by(id: params[:version_id])
            PageBuilderWorker.perform_async(@layout.id, publish_layout.id, false)
            render json: {success: true}
          end

          def get_styling
            styles = @store.layout_setting.preferences
            primary = styles[:primary_font]
            secondary = styles[:secondary_font]
            bg_color_primary = styles[:bg_color][:primary]
            bg_color_secondary = styles[:bg_color][:secondary]
            root = {
              "--primary-font": primary,
              "--secondary-font": secondary,
              "--primary-bg-color": bg_color_primary,
              "--secondary-bg-color": bg_color_secondary
            }
            if valid_style?(styles[:paragraph])
              p = {
                "font-family": css_font_family(styles[:paragraph][:type]),
                "color": styles[:paragraph][:colorCode],
                "font-size": css_font_size(styles[:paragraph][:size])
              }
            end
            if valid_style?(styles[:heading_1])
              h1 = {
                "font-family": css_font_family(styles[:heading_1][:type]),
                "color": styles[:heading_1][:colorCode],
                "font-size": css_font_size(styles[:heading_1][:size])
              }
            end
            if valid_style?(styles[:heading_2])
              h2 = {
                "font-family": css_font_family(styles[:heading_2][:type]),
                "color": styles[:heading_2][:colorCode],
                "font-size": css_font_size(styles[:heading_2][:size]),
              }
            end
            if valid_style?(styles[:heading_3])
              h3 = {
                "font-family": css_font_family(styles[:heading_3][:type]),
                "color": styles[:heading_3][:colorCode],
                "font-size": css_font_size(styles[:heading_3][:size])
              }
            end
            if valid_style?(styles[:heading_4])
              h4 = {
                "font-family":  css_font_family(styles[:heading_4][:type]),
                "color": styles[:heading_4][:colorCode],
                "font-size": css_font_size(styles[:heading_4][:size])
              }
            end
            if valid_style?(styles[:heading_5])
              h5 = {
                "font-family": css_font_family(styles[:heading_5][:type]),
                "color":  styles[:heading_5][:colorCode],
                "font-size": css_font_size(styles[:heading_5][:size])
              }
            end
            if valid_style?(styles[:heading_6])
              h6 = {
                "font-family": css_font_family(styles[:heading_6][:type]),
                "color": styles[:heading_6][:colorCode],
                "font-size": css_font_size(styles[:heading_6][:size]),
              }
            end
            if valid_style?(styles[:href_link])
              a = {
                "font-family": css_font_family(styles[:href_link][:type]),
                "color": styles[:href_link][:colorCode],
                "font-size": css_font_size(styles[:href_link][:size]),
              }
            end
            if valid_style?(styles[:href_link_active])
              a_hover = {
                "font-family": css_font_family(styles[:href_link_active][:type]),
                "color": styles[:href_link_active][:colorCode],
                "font-size": css_font_size(styles[:href_link_active][:size]),
              }
            end
            if valid_style?(styles[:button])
              button = {
                "font-family": css_font_family(styles[:button][:type]),
                "color": styles[:button][:colorCode],
                "font-size": css_font_size(styles[:button][:size])
              }
            end
            if valid_style?(styles[:button_active])
              button_hover = {
                "font-family": css_font_family(styles[:button_active][:type]),
                "color": styles[:button_active][:colorCode],
                "font-size": css_font_size(styles[:button_active][:size]),
              }
            end
            render json: {"root": root,p: p, h1: h1, h2: h2, h3: h3, h4: h4, h5: h5, h6: h6, "a:hover": a_hover, "button": button, ".btn": button, ".btn-primary": button,
              "button:hover": button_hover, ".btn:hover": button_hover, ".btn-primary:hover": button_hover
            }
          end

          def get_javacript
            @javascript_styling = @store.layout_setting.preferred_custom_js.html_safe rescue nil
            render json: @javascript_styling
          end

          def get_acm_certificate
            begin
              acm = Aws::ACM::Client.new()
              resp = acm.describe_certificate({certificate_arn: @store.acm_arn})
              result = {}
              result = resp.certificate.domain_validation_options if resp && resp.certificate && resp.certificate.domain_validation_options
              status = 200
            rescue Aws::ACM::Errors::ServiceError => e
              puts e.inspect
              result = {sucess: true}
              status = 200
            end
            render json: result.to_json , status: status
          end

          def load_balancer_ssl_setup_alert
            Spree::SES::Mailer.send_ssl_setup_instructions_email(@store, spree_current_user)
            render json: { success: true }.to_json, status: 200
          end

          def regenerate_dns
            @store.send_msg_to_sqs
            render json: {sucess: true}.to_json , status: 200
          end

          def send_dns_details
            if params[:to_addresses].present?
              ssl_details={cname: params[:cname], to_addresses: params[:to_addresses], ssl_certificates: JSON.parse(params[:ssl_certificates])}
              SesEmailsDataWorker.perform_async(@store.id, "iframe_dns_details", nil, ssl_details)
              render json: {success: true}.to_json, status: 200
            else
              render json: {error: "Emails must be provided"}.to_json, status: :unprocessable_entity
            end
          end

          def update_apple_passbook
            apple_passbook = @store.apple_passbook || @store.build_apple_passbook
            if apple_passbook.update(passbook_params)
              apple_passbook.update_preferences(passbook_params["preferences"])
              render_serialized_payload { serialize_resource(@store) }
            else
              render_error_payload(failure(apple_passbook).error)
            end
          end

          def clear_cache
           spree_current_store.clear_store_cache()
           render_serialized_payload { success({success: true }).value }
          end

          def client_stores
            stores = if @spree_current_user.has_spree_role?("sub_client") && !@spree_current_user.can_manage_sub_user
                       current_client.stores.where(id: @spree_current_user.allow_store_ids)
                     else
                       current_client.stores
                     end
            render_serialized_payload { serialize_store_collection(stores) }
          end

          private

          def is_stripe_ePays?(popt, store_pm)
            payment_method = Spree::PaymentMethod.find_by("spree_payment_methods.id = ? AND spree_payment_methods.type = 'Spree::Gateway::StripeGateway'",
                                                          store_pm[:payment_method_id])
            payment_method and popt[:payment_option] == 'ePays'
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::StoreSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields,
                params: {
                  user: @spree_current_user
                }
            ).serializable_hash
          end

          def serialize_store_collection(collection)
            Spree::V2::Storefront::StoreSerializer.new(collection,
            collection_options(collection)).serializable_hash
          end

          def collection_options(collection)
            {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: resource_includes,
              fields: sparse_fields,
              params: {
                user: @spree_current_user
              }
            }
          end

          def set_store
            if @spree_current_user.user_with_role("client")
              @store = current_client.stores.find_by('spree_stores.id = ?', params[:id])
            else
              @store = current_client.stores.sub_client_stores(@spree_current_user.allow_store_ids).find_by('spree_stores.id = ?', params[:id]) # render serialized payload method auto returns 'Resource Not Found Error'
            end
          end

          def set_layout
            @layout = @store.html_page.html_layout
          end

          def preferred_layout
            @layout_setting = @store.layout_setting
            @layout_setting ||= @store.build_layout_setting
          end

          def preferred_email_config
            @email_config = @store.email_notification_configuration
            @email_config ||= @store.build_email_notification_configuration
          end

          def preferred_gift_card_config
            @gift_card_config = @store.gift_card_pdf
            @gift_card_config ||= @store.build_gift_card_pdf
          end

          def preferred_invoice_config
            @invoice = @store.invoice_configuration
            @invoice ||= @store.build_invoice_configuration
          end

          def set_settings
            @settings = @store.general_settings
            @settings ||= @store.build_general_settings
          end

          def store_params
            params.require(:store).permit(:test_mode, :note, :show_brand_name, :default_url, :checkout_flow, :max_cart_transaction, :min_custom_price, :max_custom_price, :fulfilment_start_date, :allow_fulfilment, :lalamove_pickup_order_tag_id, :lalamove_complete_order_tag_id, :lalamove_url, :lalamove_market, :lalamove_pk, :lalamove_sk, :decimal_points, :currency_formatter, :ses_emails, :contact_number, :mail_to, :customer_service_url, :burger_menu_theme, :google_site_verification_tag, :is_www_domain, :enable_checkout_terms, :checkout_terms, :enable_marketing, :marketing_statement, :is_show_swatches, :line_username, :ts_gift_card_url, :ts_gift_card_email, :ts_gift_card_password, :refunds_timeline, :per_page, :bcc_emails, :max_image_width, :max_image_height, :carosel_spacing, :top_category_url_to_product_listing, :page_title, :copy_rights_text, :subscription_title, :subscription_text, :description, :default_currency, :name, :url, :meta_description, :meta_keywords, :seo_title, :mail_from_address, :code, :recipient_emails, :google_translator, :ask_seller, :vendor_visibility, :mailchip, :fb_username, :insta_username, :twitter_username, :pinterest_username, :linkedin_username, :recaptcha_key, :country_specific, :truncated_text_length, :show_ship_countries, :adyen_origin_key, :ship_to_label, :download_order_details, :default_tax_zone_id, :enable_client_default_tax, :enable_review_io, :reviews_io_store_id, :reviews_io_bcc_email, :hawk_username, :hawk_password, :hawk_store_channel_code, :hawk_api_url, :reviews_io_api_key, :givex_user, :givex_password, :givex_url, :givex_secondary_url, :enable_finance_report, :finance_report_to, :finance_report_cc, :excluded_tax_label, :included_tax_label, :sales_report_password, :schedule_report, :stripe_express_account_id, :stripe_standard_account_id, :enable_v3_billing, :sabre_reference_code, :hcaptcha_key, :prefix, :suffix, :shipping_method_ids => [], :country_ids => [], :gtm_tags => [], :zone_ids => [], store_payment_methods_attributes: [], :swatches => [], supported_currencies: [])
          end

          def invoice_params
            params.require(:invoice).permit(:brand, :address, :phone, :email, :notes)
          end

          def passbook_params
            params.require(:store).permit(:pass, :p12_password, preferences: {})
          end

          def check_domain_availability
            render_error_payload("Store name can not be blank.", 422) and return unless store_params[:name].present?
            
            domain = store_params[:name].parameterize + ".techsembly.com"
            render_error_payload("Storename has already been taken.", 422) and return unless Spree::Store.domain_available?(domain)
          end
        end
      end
    end
  end
end
