require 'sidekiq/web'
require 'sidekiq/cron/web'
Rails.application.routes.draw do
  # root 'storefront#home'
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to
  # Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the
  # :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being
  # the default of "spree".
  #
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  Spree::Core::Engine.routes.default_url_options = Rails.application.config.action_mailer.default_url_options

  mount Spree::Core::Engine, at: '/'

  constraints(:host => ENV['SIDEKIQ_URL']) do
    mount Sidekiq::Web => '/sidekiq'
  end

  direct :rails_public_blob do |blob|
    # Preserve the behaviour of `rails_blob_url` inside these environments
    # where S3 or the CDN might not be configured
    if Rails.env.development? || Rails.env.test?
      route = if blob.is_a?(ActiveStorage::Variant)
        :rails_representation
      else
        :rails_blob
      end
      route_for(route, blob)
      # File.join(ENV.fetch("CDN_HOST"), blob.key)
    else
      # Use an environment variable instead of hard-coding the CDN host
      # You could also use the Rails.configuration to achieve the same
      File.join(ENV.fetch("CDN_HOST"), blob.key)
    end
  end

  get '/admin/sftp/login', to: 'home#sftp_login_form'
  post '/admin/sftp/download', to: 'home#sftp_login'

  Spree::Core::Engine.add_routes do
    namespace :api, defaults: { format: 'json' } do

      namespace :v1 do
        put '/classifications/bluk_update', to: 'classifications#bulk_update'
      end

      namespace :v2 do
        namespace :webhooks do
          resources :refunds, only: [] do
            collection do
              post "adyen_refund_notification"
            end
          end
        end

        namespace :storefront do
          resources :vendor_groups do
            collection do
              get 'products'
            end
          end
          resources :linked_inventories, only: [:index, :show, :create, :update, :destroy] do
          end
          resources :link_payments, only: [] do
            collection do
              post "adyen_payment_link_notification"
              put "regenerate"
            end
          end
          resources :front_desk_credentials, only: %i[create show update] do
            collection do
              get 'get_supported_currencies'
              get 'get_data'
              put 'update_data'
            end
          end

          resources :whitelist_emails,  only: %i[index create destroy] do
            member do
              post 'resend_verification'
            end
          end

          get 'authorize_braintree_client', to: 'checkout#braintree_client'
          post '/stripe_client_secret', to: 'checkout#stripe_client_secret'
          post 'response_eghl', to: 'checkout#response_eghl'
          post 'response_eghl_call_back', to: 'checkout#response_eghl_call_back'
          get  'response_eghl', to: 'checkout#redirect_front_end'
          put 'cart/ts_card_topup', to: 'cart#ts_card_topup'
          put 'cart/ts_card_activation', to: 'cart#ts_card_activation'
          put 'cart/ts_transaction_emails', to: 'cart#ts_transaction_emails'
          post 'cart/create_payment_cart', to: "cart#create_payment_cart"
          post 'cart/create_iframe_cart', to: "cart#create_iframe_cart"
          get '/checkout/refresh', to: 'checkout#refresh_cart'
          get 'checkout', to: 'checkout#show'
          post 'checkout/complete_crypto_payment', to: 'checkout#complete_crypto_payment'
          post 'checkout/crypto_payment', to: 'checkout#crypto_payment'
          get 'checkout/is_synched_cart', to: 'checkout#is_synched_cart'
          get 'checkout/ensure_product_in_stock', to: 'checkout#ensure_product_in_stock'
          put 'checkout/update_billing_address', to: 'checkout#update_billing_address'
          put '/request_refund/:id', to: 'line_items#request_refund'
          post 'checkout', to: 'checkout#adyen_three_ds'
          post 'attach_image', to: 'homes#attach_image'
          post 'attach_image_file', to: 'homes#attach_image_file'
          put 'update_scheduled_reports/:id', to: 'homes#update_scheduled_reports'
          post 'upload_image', to: 'homes#upload_image'
          get '/navbar_data' , to: 'html_components#navbar_data'
          get '/footer_data', to: 'html_components#footer_data'
          get '/newletter_data', to: 'html_components#newletter_data'
          get '/variants', to: 'variants#index'
          get '/get_reimbursements_data', to: 'return_authorizations#get_reimbursements_data'
          put '/reimbursements/:id', to: 'reimbursements#update_status'
          resources :clients ,only: %i[create update] do
            collection do
              post 'upload_json'
              put 'sign_up'
              get 'get_client'
              get 'reporting_exchange_rates'
              post 'create_ts_client'
              post 'iframe_signup'
              get 'is_new_company'
              put 'iframe_business_details'

            end
            member do
              get 'product_csv'
            end
          end
          resources :ts_gift_cards, only: %i[create] do
            member do
              get 'pdf_details'
              put 'cancel_gift_cards'
              put 'update_status'
            end
          end
          resources :payment_methods ,only: %i[create show update index]
          resources :product_batches ,only: %i[create]
          resources :stock_products ,only: %i[index update] do
            collection do
              get 'available_products'
            end
          end
          # patch 'pay_pal_express_checkout', to: 'checkout#paypal_checkout'
          resources :users ,only: %i[create update index show destroy] do
            collection do
              put 'update_user'
              get 'user_account'
              get 'profile'
              post 'merge_cart'
              get 'cart'
              post 'send_otp_email'
              post 'verify_otp'
              post 'subscribe', to: 'users#mailchimp_subscription'
              get 'search_bar_taxons'
              get 'is_new_user'
              post 'create_sub_client'
              post 'create_fd_user'
              post 'create_bulk_sub_client'
              post 'import_sub_client'
              post 'givex_balance'
              get 'is_guest_exist'
              post 'email_for_customer_support'
              get 'get_user_roles'
              get 'export_users'
              get 'service_login_users'
              get 'export_client_users'
            end
            member do
              get 'scheduled_reports'
            end
          end

          resources :persona, only: [:index]

          resources :vendors,only: %i[index show create update] do
            collection do
              # delete 'destroy_multiple'
              get 'profile'
              post 'upload_image'
              post 'sign_up'
              put 'vendor_account'
              put 'update_billing_address'
            end
            member do
              post 'adyen_account'
              get 'get_vendor'
            end
          end
          resources :pages,only: %i[index show create update destroy] do
            collection do
              delete 'destroy_multiple'
              get 'get_by_url'
            end
          end

          resources :notifications,only: %i[create index destroy] do
            collection do
              delete 'destroy_multiple'
              put 'mark_multiple'
            end
            member do
              put 'mark'
            end
          end

          resources :orders,only: %i[index show update] do
            resources :return_authorizations, only: %i[create]
            member do
              put 'mark_status'
              put 'send_email_to_customer'
              put 'send_emails'
              get 'invoice'
              put 'update_shipment_card_schedule'
              get 'update_order_spread_sheet'
              post 'refund'
              patch 'subscribe_marketing_data'
              put 'update_notes'
            end
            collection do
              get 'ts_giftcard_givex'
              get 'csv_details'
              get 'download_report'
              get 'download_order_gift_cards'
              get 'download_ppi_report'
              get 'download_report_finance_sale'
              get 'download_ts_givex_sale_report'
              get 'search_orders_customer_service'
              get 'dashboard_orders'
              get 'download_apple_pass'
            end
          end

          resources :products,only: %i[create index destroy show update] do
            collection do
              delete 'destroy_multiple'
              put 'trashbin'
              put 'reinstate'
              put 'approved'
              put 'change_status'
              get 'option_types'
              get 'personlizations'
              post 'import_stocks'
              get 'stores'
              get 'get_filters'
              get 'get_properties'
              post 'upload_image'
              get 'shipping_categories'
              get 'taxons'
              get 'viewed_recently'
              post 'recent'
              get 'image'
              put 'add_to_category'
              put 'remove_from_category'
              get 'curation_products'
              get 'category_products'
              get 'iframe_flow_product'
              post 'attach_variant_image'
            end
            member do
              put 'update_stock'
              put 'update_iframe_product'
              get 'related_products'
            end
          end

          resources :line_items, only: %i[update] do
            collection do
              post 'upload_image'
              get 'best_selling_report'
              get 'get_csv'
              put 'bulk_update'
              put 'send_gift_cards_email'
              put 'send_gift_cards_sms'
            end
            member do
              put 'regenerate_gift_cards'
              put 'update_recipient_email'
            end
            member do
              put 'update_item'
            end
          end

          resources :client_email_templates, only: %i[update index create] do
            collection do
              put 'send_sample_email'
            end
          end

          resources :bulk_orders, only: %i[index update create destroy show] do
            collection do
              put 'attach_shipping_address'
            end
          end
          resources :exchange_rates,only: %i[index update create]
          resources :markups,only: %i[index update create]
          resources :galleries
          resources :redirects, only: %i[index update create destroy show]
          resources :stores,only: %i[index update create destroy show], as: :my_store do
            collection do
              get 'all_stores'
              get 'is_new_store'
              get 'get_iframe_store_layout_settings'
              put '/:id/create_store_onboarding' => :create_store_onboarding
              get 'client_stores'
            end
            get '/get_styling' => :get_styling
            get '/get_javacript' => :get_javacript
            member do
              put 'publish'
              put 'copy_version'
              get 'publish_html_layouts'
              put 'update_pickup_address'
              put 'update_v3_flow_address'
              put 'update_payment_methods'
              put 'update_strip_info'
              get 'stripe_dashboard'
              post 'update_apple_passbook'
              post 'send_dns_details'
            end
            resources :html_components do
              resources :html_ui_blocks
              member do
                delete 'destroy_logo'
              end
              collection do
                put 'update_all_components'
                put 'copy_in_publish_layout'
              end
            end
            resources :mailchimp_settings ,only: %i[create update]
            member do
              put 'layout_settings'
              put 'iframe_store_layout_settings'
              # put 'email_configurations'
              put 'gift_card_pdf'
              put 'invoice_configurations'
              put 'general_settings'
              get 'get_acm_certificate'
              get 'regenerate_dns'
            end

            resources :email_templates, only: %i[update index create destroy] do
              collection do
                put 'send_sample_email'
              end
            end

          end
          resources :general_settings,only: %i[index] do
            collection do
              get 'supported_currency'
              get 'categories_json'
              get 'products_json'
            end
          end
          resources :passwords,only: %i[create] do
            collection do
              put 'generate_reset_password_token'
            end
          end
          resources :questions,only: %i[index show create] do
            member do
              post 'reply'
            end
          end

          resources :shipping_methods,only: %i[index show create update destroy] do
            collection do
              get 'form_data'
            end
          end

          resources :tax_rates,only: %i[index show create update destroy] do
            collection do
              delete 'destroy_multiple'
              get 'form_data'
            end
          end

          resources :addresses,only: %i[index show create update destroy]

          resources :wishlists do
            collection do
              get 'user_wishlist'
            end
          end

          resources :wished_products, only: [:create, :update, :destroy]

          resources :taxons do
            collection do
              get 'breadcrums'
              get 'get_dropdown_data'
            end
          end

          resource :countries, except: [:show] do
            collection do
              get 'remove_countries_with_store_name'
            end
          end

          resources :properties
          resources :option_types
          resources :shipping_categories,only: %i[index show create update destroy] do
            collection do
              delete 'destroy_multiple'
            end
          end
          resources :tax_categories,only: %i[index show create update destroy] do
            collection do
              delete 'destroy_multiple'
            end
          end
          resources :zones,only: %i[index show create update destroy] do
            collection do
              post 'create_fulfilment_zone'
            end
            member do
              put 'assign_order'
              put 'update_fulfilment_zone'
            end
          end
          resources :promotion_categories, only: %i[index show create update destroy] do
            collection do
              delete 'destroy_multiple'
            end
          end
          resources :promotion_rules, only: %i[index show create update destroy]
          resources :promotion_actions, only: %i[index create update destroy]

          resources :promotions, only: %i[index show create update destroy] do
            collection do
              get 'form_data'
              delete 'destroy_multiple'
            end
          end

          resources :reports, only: %i[show create] do
            # collection do
            #   post ''
            # end
          end

          resources :follows do
            collection do
              put 'approve'
              put 'reject'
            end
          end

          resources :shipments, only: [:index, :update] do
            collection do
              post 'update_status_with_lalamove'
            end
            resources :fulfilment_info do
              member do
                put 'update_replacement'
                post 'create_replacement'
              end
            end
          end

          resources :order_tags,only: %i[index show create update destroy] do
            member do
              put 'send_email'
            end
          end
          resources :tags,only: %i[index show create update destroy]

          resources :lalamoves,expect: %i[index show create update destroy] do
            collection do
              put 'get_quotation'
              put 'place_order'
              put 'cancel_order'
            end
          end

          resources :givex_cards, only: [:index, :create, :show] do
            member do
              put 'send_email'
              get 'pdf_details'
              put 'cancel_gift_cards'
            end
            collection do
              post 'givex_request'
              post 'givex_activate_card'
              put 'send_sms'
            end
          end

          resources :fulfilment_team do
            collection do
              get 'team_orders'
              get 'download_fulfilment_report'
            end
          end

          resources :fulfilment_info do
            member do
              put 'marked_as_fulfiled'
            end
          end

          namespace :service_login_user do
            resources :sub_admins, only: [:create, :update, :show, :destroy] do
              collection do
                get 'clients'
                post 'authenticate_sub_client'
                delete 'destroy_multiple'
                put 'reinstate'
              end
            end

            resources :admins, only: [:show, :index] do
              collection do
                get 'clients'
                get 'profile'
                put 'update_password'
              end
            end

          end
        end
      end
    end
  end

  # TODO: if favicon.ico works then we'll have to do for apple touch icons using following routes.
  # get '/apple-touch-icon.png', to: 'storefront#apple_touch_icon'
  # get '/apple-touch-icon-precomposed.png', to: 'storefront#apple_touch_icon_precomposed'

  get '/manifest.json', to: 'storefront#manifest'
  get '/browserconfig.xml', to: 'storefront#browserconfig'

  get '.well-known/apple-developer-merchantid-domain-association', to: 'storefront#apple_domain_varify', format: :txt
  get '/vendor/:landing_page_url/products/embbed_widget', to: 'widget#index'
  get '/givex/:id', to: 'givex#show_givex_card'
  get '/tsgift/:id', to: 'givex#show_ts_card'
  get '/tsgift_ex/:id', to: 'givex#show_external_ts_card'
  get ':slug/givex/:id', to: 'givex#show_givex_card'
  get ':slug/:lang/givex/:id', to: 'givex#show_givex_card'
  get ':slug/tsgift/:id', to: 'givex#show_ts_card'
  get ':slug/:lang/tsgift/:id', to: 'givex#show_ts_card'

  get '/show_embbed_widget', to: 'widget#show_widget'
  get 'storefront/cart/data', to: "storefront#get_cart_data", format: 'js'
  get ':slug/storefront/cart/data', to: "storefront#get_cart_data", format: 'js'
  get ':slug/:lang/storefront/cart/data', to: "storefront#get_cart_data", format: 'js'


  post ':slug/api/v2/storefront/checkout', to: 'spree/api/v2/storefront/checkout#adyen_three_ds'
  post ':slug/api/v2/storefront/response_eghl_call_back', to: 'spree/api/v2/storefront/checkout#response_eghl_call_back'
  post ':slug/api/v2/storefront/response_eghl', to: 'spree/api/v2/storefront/checkout#response_eghl'
  get ':slug/api/v2/storefront/response_eghl', to: 'spree/api/v2/storefront/checkout#redirect_front_end'

  post ':slug/:lang/api/v2/storefront/checkout', to: 'spree/api/v2/storefront/checkout#adyen_three_ds'
  post ':slug/:lang/api/v2/storefront/response_eghl_call_back', to: 'spree/api/v2/storefront/checkout#response_eghl_call_back'
  post ':slug/:lang/api/v2/storefront/response_eghl', to: 'spree/api/v2/storefront/checkout#response_eghl'
  get ':slug/:lang/api/v2/storefront/response_eghl', to: 'spree/api/v2/storefront/checkout#redirect_front_end'

  put '/update_currency', to: 'spree/api/v2/storefront/orders#update_currency'
  put ':slug/update_currency', to: 'spree/api/v2/storefront/orders#update_currency'
  put ':slug/:lang/update_currency', to: 'spree/api/v2/storefront/orders#update_currency'

  post '/clear_cache', to: 'spree/api/v2/storefront/stores#clear_cache'
  post ':slug/clear_cache', to: 'spree/api/v2/storefront/stores#clear_cache'
  post ':slug/:lang/clear_cache', to: 'spree/api/v2/storefront/stores#clear_cache'
  post '/spree_oauth/token', to: 'token#create'

  # angular app routes
  controller 'storefront' do
    get '/return' => :return_init
    get '/return-items' => :return_items
    get '/return-items-details' => :return_items_details
    get '/return-items-labels' => :return_items_labels
    get '/return-item-single-label' => :return_item_single_label

    class SubCategories
      def self.matches?(request)
        return true if request.path_parameters[:category] != "rails"
      end
    end

    class SubFolderSubCategories
      def self.matches?(request)
        return true if request.path_parameters[:category] != "rails" && (request.path_parameters[:slug].present? && request.path_parameters[:slug] != "rails")
      end
    end

    class WithOutStoreSlug
      def self.matches?(request)
        store_with_first_level = CheckLevel.check_levels(request).first
        return true if store_with_first_level == false
      end
    end

    class StoreFirstLevelSlug
      def self.matches?(request)
        store_with_first_level, store_with_second_level = CheckLevel.check_levels(request)
        return true if store_with_first_level == true && store_with_second_level == false
      end
    end

    class StoreSecondLevelSlug
      def self.matches?(request)
        store_with_first_level, store_with_second_level = CheckLevel.check_levels(request)
        return true if store_with_first_level == true && store_with_second_level == true
      end
    end

    class CheckLevel
      def self.check_levels(request)
        store_url = request.env['SERVER_NAME']
        store_url&.slice! 'www.'
        domain_stores = Spree::Store.where("url like ? OR default_url like ?", "%#{store_url}%", "%#{store_url}%")
        request_path = request.path
        request_path = request_path&.split("/")&.reject { |c| c&.empty? }
        check_store_with_first_level = (store_url + "/" + request_path.first if request_path.length > 0) || ""
        store_with_first_level = domain_stores.any? { |store| (store&.url&.include?check_store_with_first_level) || (store&.default_url&.include?check_store_with_first_level)}
        check_store_with_second_level = (check_store_with_first_level + "/" + request_path.second if request_path.length > 1) || ""
        store_with_second_level = false
        store_with_second_level = domain_stores.any? { |store| (store&.url&.include?check_store_with_second_level) || (store&.default_url&.include?check_store_with_second_level)} if check_store_with_second_level.present?
        return store_with_first_level, store_with_second_level
      end
    end

    def store_front_routes
        # get 'givex-portal', to: 'givex-portal/givex-login'
        get 'givex-portal/givex-login' => :givex_login
        get 'givex-portal/givex-register' => :givex_register
        get 'givex-portal/givex-home' => :givex_home
        get 'givex-portal/givex-update' => :givex_update
        get 'givex-portal/givex-reset-password' => :givex_reset_password
        get 'givex-portal/my-cards' => :my_card
        get 'givex-portal/card-lost/:cardHash' => :card_lost
        get 'givex-portal/add-card' => :add_card
        # get 'ts-portal', to: 'ts-portal/ts-login'
        get 'ts-portal/ts-login' => :ts_login
        get 'ts-portal/ts-register' => :ts_register
        get 'ts-portal/ts-home' => :ts_home
        get 'ts-portal/ts-update' => :ts_update
        get 'ts-portal/ts-reset-password' => :ts_reset_password
        get 'ts-portal/my-cards' => :my_card
        get 'ts-portal/add-card' => :add_card
        get 'ts-portal/ts-forgot-password' => :ts_forgot_password
        get 'ts-portal/ts-forgot-password-update/:token' => :ts_forgot_password_update
        get 'givex-portal/givex-card-balance' => :givex_card_balance
        get '/preview' => :preview
        get '/version_preview/:id' => :version_preview
        get '/reports/:feed_type' => :reports
        get '/wishlist' => :wishlist
        get '/vendor/:id' => :vendor
        get '/vendor/:vendor_id/products' => :vendors_products
        get '/pages/:id' => :pages
        get '/authenticate_adyen_three_ds' => :adyen_auth
        get '/user/account' => :user_account
        get '/user/edit' => :user_edit
        get '/user/create-address' => :user_create_address
        get '/user/address/:id' => :user_address
        get '/user/wishlist' => :user_wishlist
        get '/user/orders/:id' => :user_orders
        get '/signout' => :signout
        get '/signin-signup' => :signin_signup
        get '/forgot-password' => :forgot_password
        get '/reset-password/:token' => :reset_password
        get '/' => :home
        get '/category/:id' => :category
        get '/catalogsearch/result/:term' => :catalogsearch
        get '/cart' => :cart
        get '/checkout' => :checkout
        get '/checkout/complete' => :checkout_complete
        get '/checkout/stripe-auth' => :stripe_auth
        get '/checkout/crypto-success' => :crypto_success
        get '/gift-card-balance' => :gift_card_balance
        get '/card_topup' => :card_topup
        get '/card_activation' => :card_activation
        get '/ts-gift-card-balance' => :ts_gift_card_balance
        get '/:category/:id' => :sub_categories
        get 'sitemap' => 'sitemaps#download', defaults: { format: 'xml' }
        get 'robots' => 'sitemaps#download_robots_sitemap', defaults: { format: 'txt' }
        get '/favicon.ico', to: 'storefront#favicon'
    end

    constraints StoreSecondLevelSlug do
      scope '/:slug/:lang' do
        store_front_routes
        constraints SubFolderSubCategories do
          get '/:category/:id/:sub' => :sub_categories
          get '/:category/:id/:sub/:sub1' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2/:sub3' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2/:sub3/:sub4' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2/:sub3/:sub4/:sub5' => :sub_categories
        end
        get '/:id' => :sub_categories
      end
    end

    constraints StoreFirstLevelSlug do
      scope '/:slug' do
        store_front_routes
        constraints SubFolderSubCategories do
          get '/:category/:id/:sub' => :sub_categories
          get '/:category/:id/:sub/:sub1' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2/:sub3' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2/:sub3/:sub4' => :sub_categories
          get '/:category/:id/:sub/:sub1/:sub2/:sub3/:sub4/:sub5' => :sub_categories
        end
        get '/:id' => :sub_categories
      end
    end

    constraints WithOutStoreSlug do
      store_front_routes
      constraints SubCategories do
        get '/:category/:id/:sub' => :sub_categories
        get '/:category/:id/:sub/:sub1' => :sub_categories
        get '/:category/:id/:sub/:sub1/:sub2' => :sub_categories
        get '/:category/:id/:sub/:sub1/:sub2/:sub3' => :sub_categories
        get '/:category/:id/:sub/:sub1/:sub2/:sub3/:sub4' => :sub_categories
        get '/:category/:id/:sub/:sub1/:sub2/:sub3/:sub4/:sub5' => :sub_categories
      end
      get '/:id' => :sub_categories
    end

  end


end
