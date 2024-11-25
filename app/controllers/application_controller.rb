class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

	include Spree::XssValidationConcern

	def set_current_client
		@client = current_store&.client
	end

	def render_not_found
		render :file => "#{Rails.root}/public/404.html",  :status => 404
	end

	def render_not_authorized
		render :file => "#{Rails.root}/public/422.html",  :status => 422
	end

	def render_404_page
		render_not_found if @store.blank?
	end

	def current_store
		set_store
		check_redirect(@store) if @store.present?
		@store
	end

	def current_store_without_redirection
		set_store
	end

	private

	def set_store
		store_domain = request.domain
		subdomain = request.subdomain
		store_domain = "#{subdomain}.#{store_domain}" if subdomain.present? && subdomain != "www"
		store_domain = store_domain + "/" + params[:slug] if params[:slug]
		store_domain = store_domain + "/" + params[:lang] if params[:lang]
		@store = Spree::Store.find_by("url = ? OR default_url = ?", store_domain, store_domain)
	end

	def check_redirect(store)
		redirect = store.redirects.find_by("spree_redirects.from IN (?)", [request.fullpath, request.fullpath.split('?').first])
		if !redirect.blank?
			redirect_to_path = redirect.type_redirect == "absolute" ? redirect.to : "https://" + store.url + redirect.to
			redirect_to_path = request.query_string.present? ? "#{redirect_to_path}?#{request.query_string}" : redirect_to_path
			redirect_to redirect_to_path
		end
	end

	def mailchimp_store_id
		@store_id = ::SpreeMailchimpEcommerce.configuration(current_store&.id).mailchimp_store_id
	end
end
