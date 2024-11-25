class StorefrontController < ApplicationController
	include Spree::Api::V2::Storefront::HtmlComponentHelper
	include MixPanel
	protect_from_forgery except: :get_cart_data

	layout "storefront", except: [:home, :preview, :version_preview, :get_cart_data]
	layout "storefront_home", only: [:home, :preview, :version_preview]
	before_action :set_current_client
	before_action :render_404
	before_action :set_header_and_footer_and_order, except: [:preview, :version_preview]
	before_action :set_header_jsons
	before_action :set_cookies
	before_action :set_home_meta_data, only: [:home]
	before_action :set_sub_category_meta_data ,only: [:sub_categories]
	before_action :set_vendor_meta_data ,only: [:vendor]
	before_action :set_vendor_meta_data_for_view_all ,only: [:vendors_products]
	before_action :render_not_authorized, only: [:signin_signup, :wishlist, :user_wishlist, :user_account, :user_edit, :user_create_address, :user_address, :user_orders, :forgot_password, :reset_password], if: Proc.new{ @store.checkout_v3? }

  [:wishlist, :vendor, :user_account, :user_edit, :user_create_address, :user_address, :gift_card_balance,
    :user_wishlist, :user_orders, :vendors_products, :signout, :signin_signup, :forgot_password, :reset_password,
		:category, :catalogsearch, :cart, :checkout, :stripe_auth, :sub_categories, :pages, :checkout_complete,
		:ts_gift_card_balance,:givex_portal,:givex_login, :givex_register, :givex_home, :givex_update, :givex_reset_password, :my_card, :crypto_success,
		 :add_card,:card_lost, :givex_card_balance, :ts_portal,:ts_login, :ts_register, :ts_home, :ts_update, :ts_reset_password, :ts_forgot_password, :ts_forgot_password_update
  ].each do |meth|
  	define_method meth do |*my_arg|
			if @store.preferred_single_page || iframe_route?
				render_not_authorized
			else
	  		render "storefront/home"
			end
  	end
	end

	def card_topup
		spo_checkout
	end

	def card_activation
		spo_checkout
	end

	def home
		if @store.preferred_single_page || iframe_route?
			render_not_authorized
		elsif @components
			render "storefront/new_home"
		else
			render json: "Please design your store and publish".to_json
		end
	end

	def preview
		@layout = @store&.html_page.html_layout
		@components = @layout.html_components.includes(html_ui_blocks: [:html_links, html_ui_block_sections: [:html_links]])
		set_header_and_footer(@components)
		render "storefront/new_home"
	end

	def get_cart_data
		@toggle = params[:toggle].present? ? false : true
		render  "storefront/get_cart_data"
	end

	def version_preview
		@layout = @store&.html_page.publish_html_layouts.find_by('spree_publish_html_layouts.id = ?', params[:id])
		@components = @layout.html_components.includes(html_ui_blocks: [:html_links, html_ui_block_sections: [:html_links]])
		set_header_and_footer(@components)
		render "storefront/new_home"
	end

	def reports
		feed_type = params[:feed_type]
		if feed_type.present? && @store.present?
			report = @store.reports.with_feed_type(feed_type)&.last
			report = @store.reports.with_feed_type(feed_type).find_by('spree_reports.id = ?', params[:report_id]) if params[:report_id].present?
			if report.present? && report.attachment.present? && report.attachment.blob.present?
				send_data report.attachment.blob.download, filename: report.attachment.filename.to_s, content_type: report.attachment.content_type
			else
				render plain: "No Such Report"
			end
		end
	end

	def set_home_meta_data
		@tab_title = @store&.page_title
		@description = @store&.description
		@og_title = @store&.seo_title
		@og_description = @store&.meta_description
		@og_type = 'website'
		@data_attribute = 'home'
		@image_url = @store.active_storge_url(@store&.og_image)
	end

	def render_404
		render_not_found if current_store.blank? && @client.blank?
	end

	def apple_domain_varify
		render '.well-known/apple-developer-merchantid-domain-association.txt', layout: false, content_type: 'text/plain'
	end

	# TODOs: implement following methods to load store specific apple touch icons.
	# def apple_touch_icon
	# end
	# def apple_touch_icon_precomposed
	# end

	def favicon
		if @store&.favicon&.attached?
			send_data @store.favicon.blob.download, filename: @store.favicon.filename.to_s, content_type: @store.favicon.content_type, disposition: 'inline'
		else
			render json: { error: 'Favicon not attached' }, status: :not_found
		end
	end

	def manifest
		# TODO: yet its for testing. 
		# if it works then make a json view to render for store specific manifest.json
		send_file(File.join(Rails.root, "public", "manifest.json"))
	end

	def browserconfig
		# TODO: yet its for testing. 
		# if it works then make a xml view to render for store specific browserconfig.xml
		send_file(File.join(Rails.root, "public", "browserconfig.xml"))
	end


	def set_sub_category_meta_data
		taxon_permalink = "categories"
		taxon_permalink += "/#{params[:category]}" if params[:category].present?
		taxon_permalink += "/#{params[:id]}" if params[:id].present?
		taxon_permalink += "/#{params[:sub]}" if params[:sub].present?
		taxon_permalink += "/#{params[:sub1]}" if params[:sub1].present?
		taxon_permalink += "/#{params[:sub2]}" if params[:sub2].present?
		taxon_permalink += "/#{params[:sub3]}" if params[:sub3].present?
		taxon_permalink += "/#{params[:sub4]}" if params[:sub4].present?
		taxon_permalink += "/#{params[:sub5]}" if params[:sub5].present?

		taxon = @client&.taxons&.find_by(permalink: taxon_permalink)
		@image_url = @store&.active_storge_url(@store&.og_meta_image)
		@product_detail = false
		@data_attribute = ''
		if taxon.present?
			@tab_title =  taxon&.meta_title&.present? ? taxon&.meta_title : taxon&.name
			@description = taxon&.meta_description&.present? ? taxon&.meta_description : taxon&.description
			@og_type = 'Category'
			@data_attribute = 'category'
			@og_title = @store&.seo_title
			@og_description = @store&.meta_description
		else
			@product_detail = true
			if params[:product_preview]
				p = @store&.products&.find_by(slug: params[:id], type: nil) or render_not_found
			else
				p = @store&.products&.untrashed&.excluding_daily_stock&.approved&.active_vendor_products&.find_by(slug: params[:id]) or render_not_found
			end

			if p.present?
				@images = p.variant_images
				@detail_page_size = @store.max_image_width.to_s + "x" + @store.max_image_height.to_s + ">"
				image = p&.images&.where(base_image: true)&.first&.present? ? p&.images&.where(base_image: true)&.first : p&.images&.first
				image_url = image.present? ? image.active_storge_url(image&.attachment) : ""

				@tab_title = p&.meta_title&.present? ? p&.meta_title : p&.name
				@product_name = p&.name
				@description = p&.meta_description&.present? ? p&.meta_description : p&.description
				@og_title = @tab_title
				@og_description = @description
				@image_url = image_url
				@og_type = 'Product'
				@data_attribute = 'product'

				@url = @store.url + "/" + p&.slug
				@brand = p&.vendor&.name
				@availability = p&.stock_status ? 'In stock' : 'Out of stock'
				@condition = 'new'
				@price = p&.price_values(cookies[:curency])[:final_price]
				@currency = cookies[:curency]
				@retailer_item_id = p&.vendor_sku
				@item_group_id = p&.sku
			end
		end
	end

	def set_header_jsons
		social_media_usernames = {fb: @store&.fb_username, insta: @store&.insta_username,
		                          pinterest: @store&.pinterest_username, twitter: @store&.twitter_username,
		                          linkedin: @store&.linkedin_username, line: @store&.line_username}

		store_item_visibility = {vendorVisibility: @store&.vendor_visibility, askSeller: @store&.ask_seller,
		                         googleTranslator: @store&.google_translator, showMailChimp: @store&.mailchip }
		storeLogo = ''
		storeLogoAlt = ''
		if @store&.new_layout == true
			image_block = @store&.html_page&.publish_html_layouts&.where(publish: true, active: true)&.first&.html_components&.where(type_of_component:'logo')&.first&.html_ui_blocks&.first
			attachment = image_block&.image&.attachment
			storeLogo = image_block.active_storge_url(attachment) if attachment
			storeLogoAlt = image_block&.alt
		else
			storeLogo = @store&.active_storge_url(@store&.logo)
			storeLogoAlt = "Store Logo"
		end
		category_data = {categories: @client.taxons.map{|t| t.name.upcase}, categoriesUrl: @client.taxons.not_vendor.map{|t| t.permalink.split('/').last}}
		store_url = @store.try(:url)
		if store_url.present? && store_url['www.'].nil? && @store.is_www_domain
			store_url = "www.#{store_url}"
		end
		line_item_count = @selected_order.present? ? @selected_order.line_items.count : 0

		allow_sub_folder_upto = 0
		allow_sub_folder_upto = 1 if params[:slug].present?
		allow_sub_folder_upto = 2 if params[:lang].present?
		@use_sub_folder_upto = (allow_sub_folder_upto == 0? false : true) #we will use this variable in rails views to make subfoldering urls

		@data = {socialLinks: social_media_usernames,
		         storeDiscription: @store&.description, storeName: @store&.name, storeLogo: storeLogo, storeLogoAlt: storeLogoAlt,
						 subscriptionTitle: @store&.subscription_title, subscriptionText: @store&.subscription_text, adyenOriginKey: @store&.adyen_origin_key,
					   recaptchaKey: @store&.recaptcha_key, copyRightsText: @store&.copy_rights_text, generalSettings: (@store&.general_settings&.preferences || {}),
					   topCategoryUrlToProductListing: @store&.top_category_url_to_product_listing, stripeKey: @store&.stripegateway_payment_method&.preferred_publishable_key,
					   current_store_url: store_url, storeItemVisibility: store_item_visibility, caroselSpacing: @store&.carosel_spacing,
					 	 truncatedTextLength: @store&.truncated_text_length, defaultThumbnail: @store&.active_storge_url(@store&.default_thumbnail),
						 perPage: @store&.per_page, downloadOrderDetails: @store&.download_order_details, brandFollow: @client.allow_brand_follow, clientLayout: @store.new_layout,
						 enableReviewIo: @store&.enable_review_io, payPalId: @store&.paypal_gateway&.preferred_client_id,
						 reviewsIoApiKey: @store&.reviews_io_api_key, reviewsIoStoreId: @store&.reviews_io_store_id, allowSubFolderUrls: allow_sub_folder_upto,
						 tsGiftCardEmail: @store&.ts_gift_card_email, tsGiftCardPassword: @store&.ts_gift_card_password, tsGiftCardUrl: @store&.ts_gift_card_url,
						 storeId: @store.id.to_s, storeCode: @store.code, stripeStandardAccountId: @store&.send(:stripe_connected_account),
						 enableCheckoutTerms: @store.enable_checkout_terms, checkoutTerms: @store.checkout_terms,
						 enableMarketing: @store.enable_marketing, marketingStatement: @store.marketing_statement, checkoutFlow: @store.checkout_flow,
						 line_item_count: line_item_count, preferences: @store.preferences,  maxCartTransaction: max_cart_transaction_value, showBrandName: @store.show_brand_name,
						 singlePageStore: @store.preferred_single_page, enable_v3_billing: @store.enable_v3_billing, enable_security_message: @store.preferred_enable_security_message,
						 store_type: @store.preferred_store_type, iframe_urls: @store.preferred_iframe_urls, default_products_filter: @store.preferred_default_products_filter,
						 hcaptchaKey: @store&.hcaptcha_key }

		currency_symbol = Money.new(100, @store&.default_currency).currency.symbol
		iframe_data, store_id = {}, @store&.id&.to_s
		iframe_data = {
			iframe: {
				"#{store_id + '_store_type'}": @store&.preferred_store_type,
				"#{store_id + '_iframe_urls'}": @store&.preferred_iframe_urls,
				"#{store_id + '_store'}": @store&.id,
				"#{store_id + '_storeSymbol'}": @store&.code.upcase,
				"#{store_id + '_storeCode'}": @store&.code,
				"#{store_id + '_preferred_store'}": @store&.code,
				"#{store_id + '_decimal_points'}": @store&.decimal_points,
				"#{store_id + '_currency_formatter'}": @store&.currency_formatter,
				"#{store_id + '_curency'}": @store&.default_currency,
				"#{store_id + '_curencySymbol'}": currency_symbol
			}
		} if @store&.preferred_store_type&.eql?("iframe")
		
		@data.merge!(iframe_data)
		@data.merge!(category_data)
	end

	private

	def iframe_route?
     @store.preferred_store_type == "iframe" && ["sub_categories", "checkout", "checkout_complete", "crypto_success"].exclude?(params[:action])
	end

	def spo_checkout
		if @store.preferred_single_page
			render "storefront/single_page_checkout"
		else
			render_not_authorized
		end
	end

	def max_cart_transaction_value
		return nil if @store.blank?
		return @store&.max_cart_transaction.to_i unless @store&.preferred_custom_amount_exchangeable

		currency = cookies["#{@store&.id&.to_s + '_curency'}"&.to_sym]
		exchange_rate = @client&.currencies&.with_out_vendor_currencies&.find_by(name: @store&.default_currency)&.exchange_rates&.find_by(name: currency)
		(exchange_rate&.value.to_f * @store&.max_cart_transaction.to_f)&.to_i
	end

	def set_current_client
		@client = current_store&.client
	end

	def set_cookies
		cookies["#{@store.id.to_s + '_store'}".to_sym] = {:value => @store.id}
		cookies["#{@store.id.to_s + '_storeSymbol'}".to_sym] = {:value => @store.code.upcase}
		cookies["#{@store.id.to_s + '_storeCode'}".to_sym] = {:value => @store.code}
		cookies["#{@store.id.to_s + '_preferred_store'}".to_sym] = {:value => @store.code}
		cookies["#{@store.id.to_s + '_decimal_points'}".to_sym] = {:value => @store.decimal_points}
		cookies["#{@store.id.to_s + '_currency_formatter'}".to_sym] = {:value => @store.currency_formatter}
		curreny_cookie = cookies["#{@store.id.to_s + '_curency'}".to_sym]
		if curreny_cookie.blank? ||  @store.supported_currencies.exclude?(curreny_cookie)
			store_currency = @store.default_currency
			cookies["#{@store.id.to_s + '_curency'}".to_sym] = {:value => store_currency}
			symbol = Money.new(100, cookies[:curency]).currency.symbol
			cookies["#{@store.id.to_s + '_curencySymbol'}".to_sym] = {:value => symbol}
		end
	end

	def set_header_and_footer_and_order
		@layout = @store&.html_page&.publish_html_layouts&.where(publish: true, active: true)&.first
		@components = @layout&.html_components&.includes(html_ui_blocks: [:html_links, html_ui_block_sections: [:html_links]])
		if @components
			set_header_and_footer(@components)
			@client_stores = {}
			@client.stores.pluck('code, url').each{|client_store| @client_stores[client_store[0]] = client_store[1]}
			@client_stores = @client_stores.to_json
			if cookies["#{@store.id.to_s + '_order_token'}".to_sym]
				selected_order = Spree::Order.where(token:cookies["#{@store.id.to_s + '_order_token'}".to_sym]).includes(line_items: [:product]).first
				@selected_order = selected_order unless selected_order&.complete?
			elsif cookies[:order_token]
				order = Spree::Order.where(token: cookies[:order_token]).first
				cookies["#{order&.store.id.to_s + '_order_token'}".to_sym] = cookies[:order_token]
				cookies.delete :order_token
			end
		end
	end

	def set_header_and_footer(components)
		@footer = components.where(type_of_component:'footer')&.first&.html_ui_blocks
		@nav_bar = components.where(type_of_component:'nav_bar')&.first&.html_ui_blocks
		@logo = components.where(type_of_component:'logo')&.first&.html_ui_blocks&.first
		@copy_rights_text = @store&.copy_rights_text
	end

	def set_vendor_meta_data
		vendor = @client.vendors&.active&.active_microsite&.find_by(landing_page_url: params[:id])
		if vendor.blank?
			render_not_found
		else
			@tab_title = vendor&.landing_page_title
			@description = vendor&.description
			img = Spree::Image.where(id: vendor&.banner_image_id).first
			@image_url = img&.active_storge_url(img&.attachment)
			@data_attribute = 'vendor-microsite'
		end
	end

	def set_vendor_meta_data_for_view_all
		vendor = @client.vendors&.active&.find_by(slug: params[:vendor_id])
		if vendor.blank?
			render_not_found
		else
			@tab_title = vendor&.landing_page_title
			@description = vendor&.description
			@data_attribute = 'vendor'
		end
	end

end
