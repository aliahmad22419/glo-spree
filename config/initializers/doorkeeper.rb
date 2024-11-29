# frozen_string_literal: true
require Rails.root.join('lib/custom_token_response')
require Rails.root.join('lib/doorkeeper_error_response_decorator.rb')

Doorkeeper.configure do |conf|
  orm :active_record
  # use_refresh_token
  api_only
  base_controller 'Spree::Api::V2::BaseController'
  base_metal_controller 'Spree::Api::V2::BaseController'

  resource_owner_authenticator { current_spree_user }
  use_polymorphic_resource_owner
  resource_owner_from_credentials do

    store = Spree::Store.find_by(id: request.headers['X-Store-Id']) if request.headers['X-Store-Id'].present?
    user = if params[:user_role] == "customer"
        role = Spree::Role.find_by_name "customer" # params[:user_role]
        customers = role&.users.where(store_id: store&.id)
        customers&.find_by_email params[:username]
      elsif params[:user_role] == "customer_support"
        role = Spree::Role.find_by(name: "customer_support")
        role&.users&.find_for_database_authentication(email: params[:username])
      elsif params[:user_role] == "fulfilment_dashborad"
        Spree.user_class.joins(:spree_roles).where(spree_roles: { name: Spree::User.const_get(:FULFILMENT_ROLES) }).find_for_database_authentication(email: params[:username])
      else
        Spree.user_class.where("store_id IS NULL").find_for_database_authentication(email: params[:username])
      end

    if user.present? && user&.is_enabled? && (user.has_spree_role?(:client) || user.has_spree_role?(:sub_client) || user.has_spree_role?(:service_login_admin) || user.has_spree_role?(:service_login_sub_admin))
      Spree::OauthAccessToken.where(resource_owner_id: user.id, revoked_at: nil).update_all(revoked_at: DateTime.now)
    end
    conf.access_token_expires_in (["customer", "admin"].include?(params[:user_role]) ? nil : 10.hours)
    user if user&.valid_for_authentication? { user.valid_password?(params[:password]) } && user&.is_enabled?

  end

  admin_authenticator do |routes|
    current_spree_user&.has_spree_role?('admin') || redirect_to(routes.root_url)
  end

  grant_flows %w(password)

  access_token_class 'Spree::OauthAccessToken'
  access_grant_class 'Spree::OauthAccessGrant'
  application_class 'Spree::OauthApplication'

  access_token_methods :from_bearer_authorization, :from_access_token_param
  # using Bcrupt for token secrets is currently not supported by Doorkeeper
  hash_token_secrets fallback: :plain
  hash_application_secrets fallback: :plain, using: '::Doorkeeper::SecretStoring::BCrypt'
end

Doorkeeper::OAuth::TokenResponse.send :prepend, CustomTokenResponse
Doorkeeper::OAuth::ErrorResponse.prepend DoorkeeperErrorResponseDecorator
