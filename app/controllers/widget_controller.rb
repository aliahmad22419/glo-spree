class WidgetController < ApplicationController
	layout "widget"
	
	before_action :set_current_client, only: [:index]
	
	before_action :set_vendor_and_check_valid_domain, only: [:index]

  def index
	  @products = @vendor.products.untrashed.approved.in_stock_status.product_quantity_count.ransack().result.limit(10)
	  @base_currency = @vendor&.base_currency&.name
	  @currency_symbol = "$"
	  @currency_symbol = Spree::Currency.with_code[@base_currency] if @base_currency.present?
  end
	
	def show_widget
		@url = params[:wedgit_url]
	end
	
	def set_vendor_and_check_valid_domain
		render_not_found if params[:landing_page_url].blank?
		@vendor = Spree::Vendor.find_by(slug: params[:landing_page_url])
		host_of_request = request.headers['Referer']
		host_of_request = URI.parse(host_of_request).host if host_of_request.present?
		puts "host_of_request"*78
		puts host_of_request
		domain = @client&.embed_widgets&.find_by(site_domain: host_of_request)
		render_not_found if @vendor.blank? || domain.blank?
	end
	

end
