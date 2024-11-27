require 'uri'
module Spree::StoreDecorator
  ::ORDERS_FETCH_FROM = { 0 => :last_generated_at, 1 => :beginning_of_month } unless const_defined?(:ORDERS_FETCH_FROM)
  def self.prepended(base)
    base.class_eval do
      enum schedule_report: { every_storefront_sale: 0, once_day: 1, once_week: 2, once_month: 3 }
    end

    base.prepend Archive
    base.prepend RegisterDomain
    # remove_method :favicon
    base.preference :send_gift_card_via_sms_label, :string, default: 'Enter recipient’s phone number'
    base.preference :enable_apple_passbook, :boolean, default: false
    base.preference :enable_recently_viewed, :boolean, default: true
    base.preference :enable_more_items, :boolean, default: true
    base.preference :enabled_error_logging, :boolean, default: false
    base.preference :disable_shipping_notification, :boolean, default: false
    base.preference :enable_announcement_bar, :boolean, default: false
    base.preference :announcement_bar, :text, default: ''
    base.preference :custom_amount_exchangeable, :boolean, default: false
    base.preference :enable_customization_price, :boolean, default: true
    base.preference :orders_fetch_from, :integer, default: 0
    base.preference :enable_bonus_card_promo, :boolean, default: false
    base.preference :start_date, :string
    base.preference :end_date, :string
    base.preference :store_type, :string, default: 'normal'
    base.preference :min_purchase, :float
    base.preference :bonus_percentage, :float
    base.preference :body, :string, default: ''
    base.preference :youtube_username, :string, default: ''
    base.preference :wechat_username, :string, default: ''
    base.preference :tiktok_username, :string, default: ''
    # base.preference :stripe_statement_descriptor_suffix, :string, default: -> { client&.name.presence || name.presence }
    base.preference :single_page, :boolean, default: false
    base.preference :enable_mixpanel, :boolean, default: false
    base.preference :state_based_tax, :boolean, default: false
    base.preference :iframe_urls, :array, default: []
    base.preference :enable_security_message, :boolean, default: false
    # base.enum schedule_report: { every_storefront_sale: 0, once_day: 1, once_week: 2, once_month: 3 }

    base.after_commit :reindex_to_elastic_stack, if: :saved_change_to_show_brand_name?
    base.after_commit :update_product_currency_prices
    base.validates :url, uniqueness: true
    # has_and_belongs_to_many :products, join_table: 'spree_products_stores'
    base.has_many :store_products, class_name: 'Spree::StoreProduct'
    base.has_many :products, through: :store_products, class_name: 'Spree::Product'
    # has_many :taxonomies
    base.has_many :orders
    base.has_many :reports
    # has_many :store_payment_methods, dependent: :destroy
    base.has_many :redirects
    # has_many :payment_methods, through: :store_payment_methods
    base.has_many :store_shipping_methods
    base.has_many :shipping_methods, through: :store_shipping_methods
    base.has_and_belongs_to_many :promotion_rules, class_name: 'Spree::Promotion::Rules::Store', join_table: 'spree_promotion_rules_stores', association_foreign_key: 'promotion_rule_id'
    base.has_many :classifications, -> { order(:position) }, dependent: :delete_all, inverse_of: :store
    base.has_many :subscriptions, dependent: :destroy, class_name: "Spree::Subscription"
    base.has_many :users, dependent: :destroy, class_name: Spree.user_class.to_s
    # has_many :store_payment_methods
    # has_many :payment_methods, through: :store_payment_methods
    base.has_one :layout_setting, dependent: :destroy, class_name: 'Spree::LayoutSetting'
    base.has_one :email_notification_configuration, dependent: :destroy, class_name: 'Spree::EmailNotificationConfiguration'
    base.has_one :general_settings, dependent: :destroy, class_name: 'Spree::StoreSetting'
    base.has_and_belongs_to_many :countries, class_name: 'Spree::Country'
    base.has_one :mailchimp_setting, dependent: :destroy
    base.has_one :sitemap, class_name: 'Spree::Sitemap'
    base.has_and_belongs_to_many :pages, class_name: 'Spree::Page'
    base.has_and_belongs_to_many :properties, class_name: 'Spree::Store'
    base.has_one_attached :email_logo
    base.has_one_attached :logo
    base.has_one_attached :flag
    base.has_one_attached :favicon
    base.has_one_attached :default_thumbnail
    base.has_one_attached :og_image
    base.has_one_attached :og_meta_image
    base.has_one_attached :generic_image
    base.has_one_attached :passbook_certificate
    base.has_one :html_page, :class_name => 'Spree::HtmlPage'
    base.has_and_belongs_to_many :zones, dependent: :destroy, class_name: 'Spree::Zone'
    base.has_many :acm_cnames, dependent: :destroy, :class_name => 'Spree::AcmCname'
    base.after_create :add_layout
    base.belongs_to :pickup_address, foreign_key: :pickup_address_id, class_name: 'Spree::Address', optional: true
    base.belongs_to :v3_flow_address, foreign_key: :v3_flow_address_id, class_name: 'Spree::Address', optional: true
    base.has_many :email_templates, dependent: :destroy, :class_name => 'Spree::EmailTemplate'
    base.has_many :givex_cards, dependent: :destroy, :class_name => 'Spree::GivexCard'
    base.has_many :ts_giftcards, dependent: :destroy, :class_name => 'Spree::TsGiftcard'
    base.has_one :apple_passbook, dependent: :destroy
    base.has_many :scheduled_reports, as: :reportable, class_name: 'ScheduledReport', dependent: :destroy
    base.accepts_nested_attributes_for :scheduled_reports, allow_destroy: true
    # before_update :send_data_to_sqs
    # after_create :send_msg_to_sqs, :send_msg_to_sqs_for_default_domain
    # after_create :send_msg_to_sqs_for_default_domain
    # after_destroy :delete_route53_for_default_domain
    base.after_commit :clear_store_cache
    base.after_commit :resize_store_product_images

    base.whitelisted_ransackable_attributes = %w[name givex_url givex_password givex_user url code default_url]

		def update_iframe_store(store, product_slug)
			self.update(default_currency: store[:store_currency], supported_currencies:[store[:store_currency]], min_custom_price: store[:store_min_value], max_custom_price: store[:store_max_value])
			self.update_preferences(iframe_urls: [{label: self.default_currency, url: "https://#{self.default_url}/#{product_slug}", selected: true}])
			redirect = self&.redirects&.last
      		redirect.present?  ? redirect.update(to: "/#{product_slug}") : self.redirects.create(type_redirect: "relative", from: "/", to: "/#{product_slug}")
		end

  end

  def clear_store_cache
    key = "store-#{self.id}"
    delete_cache(key)
  end


  def mailchimp_subscription(user)
    obj = subscriptions.find_or_initialize_by(email: user.email, list_id: mailchimp_setting.mailchimp_list_id)
    obj.user_id = user.id
    obj.save
    action = (user.subscription_status || (user.news_letter ? "subscribe" : "unsubscribe"))
    result = obj.add_to_list(action)
    user.update(news_letter: action == "subscribe") if user.persisted? && result[:status] == 200
    result
  end

  def stripegateway_payment_method
    self.payment_methods.active_with_type('Spree::Gateway::StripeGateway').last
  end

  def cryptogateway_payment_method
    self.payment_methods.active_with_type('Spree::Gateway::CryptoGateway').last
  end

  def paypal_gateway
    self.payment_methods.active_with_type('Spree::Gateway::PayPalExpress').last
  end

  def add_layout
    page = create_html_page(url: url)
    layout = page.create_html_layout(type_of_layout: "full_page", name: name)
    layout.html_components.create(type_of_component: 'logo', name: 'Logo', position: 1)
    layout.html_components.create(type_of_component: 'nav_bar', name: 'Navigation Bar', position: 2)
    layout.html_components.create(type_of_component: 'footer', name: 'Footer', position: 3)
  end

  def email_config(options)
    config = self.email_notification_configuration
    return {} if config.blank?
    config.get_preference(options[:type])
  end

  def email_logo_url
    logo_url = if self.client.logo&.attached?
      self.client.active_storge_url(self.client.logo)
    elsif self.email_logo&.attached?
      self.active_storge_url(self.email_logo)
    elsif self.logo&.attached?
      self.active_storge_url(self.logo)
    end
    logo_url
  end

  def domain_url
    return url unless url["http://"].nil? && url["https://"].nil?
    "https://#{url}"
  end

  def subfoldering_url
    sub_url = self&.url&.split('/')&.drop(1)&.join('/')&.gsub('//', '/')
    return (sub_url.present? ? "/#{sub_url}" : "")
  end

  def default_tax_zone
    client_zones = client.zones
    (enable_client_default_tax ? client_zones.default_tax : client_zones.find_by_id(default_tax_zone_id))
  end

  def send_msg_to_sqs
    unless url.include?('techsembly.com')
      sqs = Aws::SQS::Client.new()
      sqs.send_message({
        queue_url: ENV['ACM_QUEUE_URL'],
        message_body: "Store Url",
        message_attributes: {
          "id" => {
            string_value: "#{self&.id}",
            data_type: "Number"
          }
        }
      })
    end
  end

  def authorize_for_stripe(code, account_type)
    response_result, strip_error = false, ""
    begin
      stripe_payment_method = self.payment_methods.active_with_type('Spree::Gateway::StripeGateway')[0]
      return { response_result: false, strip_error: 'Please set stripe payment method first', status: 403 } if stripe_payment_method.blank?

      Stripe.api_key = stripe_payment_method.preferred_secret_key
      response = Stripe::OAuth.token({
        grant_type: 'authorization_code',
        code: code
      })

      self.update_column(:"stripe_#{account_type}_account_id", response.stripe_user_id) if response.present?
      response_result = true
    rescue => e
      response_result = false
      strip_error = e
    end
    return {response_result: response_result, strip_error: strip_error}
  end

  def email_thumbnail
    active_storge_url(self.generic_image)
  end

  def orders_fetch_from_type(type)
    Spree::Store.const_get(:ORDERS_FETCH_FROM)[type]
  end

  def stripe_connected_account
    (stripe_express_account_id.presence || stripe_standard_account_id.presence)
  end

  def clear_home_cache layout_id
    key = "store-#{self.id}-#{layout_id}"
    delete_cache(key)
  end

  [:v1, :v2, :v3].each do |version|
    define_method "checkout_#{version}?" do
      self.checkout_flow.to_sym.eql?(version)
    end
  end

  def fast_track?
    preferences[:store_type] == "fast_track"
  end

  def create_routing product_slug
    redirects.create!(type_redirect: "relative", from: "/", to: product_slug)
  end

private

  def delete_cache(key)
    Rails.cache.redis_with do |conn|
      conn.keys(*args).each do |cache|
        value = cache.include?(key)
        Rails.cache.delete(cache) if value
      end
    end
  end

  def resize_store_product_images
    StoreProductImageVariantWorker.perform_async(self.id)
  end

  def update_product_currency_prices
    return unless (saved_change_to_default_tax_zone_id? || saved_change_to_enable_client_default_tax?)
    Searchkick.callbacks(:bulk) { products.find_each { |p| ProductPricesWorker.perform_async(p.id) } }
  end

  def send_data_to_sqs
    send_msg_to_sqs if url.present? && url_changed?
  end

  def send_msg_to_sqs_for_default_domain
    self.default_url = self.name.parameterize + ".techsembly.com"
    self.save
    route53 "CREATE"
  end

  def delete_route53_for_default_domain
    route53 "DELETE" if default_url.present?
  end

  def route53 action
    sqs = Aws::SQS::Client.new()
    sqs.send_message({
      queue_url: ENV['ROUTE53_QUEUE_URL'],
      message_body: "Store Default Url",
      message_attributes: {
        "defaultUrl" => {
          string_value: "#{default_url}",
          data_type: "String"
        },
        "action" => {
          string_value: action,
          data_type: "String"
        }
      }
    })
  end

  def reindex_to_elastic_stack
    ReindexProductsWorker.perform_async(products.ids)
  end
end

::Spree::Store.prepend(Spree::StoreDecorator) unless ::Spree::Store.ancestors.include?(Spree::StoreDecorator)
