module Spree
  module Api
    module V2
      module BaseControllerDecorator
        def self.prepended(base)
          # before_action :set_entity
          # before_action :not_found
          base.prepend Spree::ServiceModule::Base
          base.include Spree::Api::V2::CollectionOptionsHelpers
          base.include Spree::ActionAuthorizationConcern
          base.include Spree::XssValidationConcern
          base.before_action :sub_client_authorization
          base.before_action :unauthorized_frontdesk_user
        end

        def store_or_client_not_found
          render json: { error: "The resource you are looking for not found" }.to_json, status: 404 if current_client.blank? && storefront_current_client.blank?
        end

        def storefront_client_not_found
          render json: { error: "The resource you are looking for not found" }.to_json, status: 404 if storefront_current_client.blank?
        end

        def current_vendor
          spree_current_user.vendors.last if spree_current_user.present?
        end

        def spree_current_user
          return nil unless doorkeeper_token
          return nil unless doorkeeper_token.revoked_at.nil?

          return @spree_current_user if @spree_current_user

          doorkeeper_authorize!

          @spree_current_user ||= Spree.user_class.find_by("spree_users.id = ?", doorkeeper_token.resource_owner_id)
        end

        def spree_current_store
          if request.headers["X-Store-Id"].present?
            @spree_current_store = Spree::Store.find_by("spree_stores.id = ?", request.headers["X-Store-Id"])
          else
            store_domain = request.domain
            subdomain = request.subdomain
            store_domain = "#{subdomain}.#{store_domain}" if subdomain.present? && subdomain != "www"
            store_domain = store_domain + "/" + params[:slug] if params[:slug]
            store_domain = store_domain + "/" + params[:lang] if params[:lang]
            @spree_current_store = Spree::Store.find_by("url = ? OR default_url = ?", store_domain, store_domain)
          end
          @spree_current_store
        end
        alias try_spree_current_user spree_current_user

        def current_currency
          currency = request.headers["X-Currency"]
          @currency = currency if currency.present? && storefront_current_client.present? && storefront_current_client.supported_currencies.include?(currency)
          @currency ||= spree_current_store&.default_currency || Spree::Config[:currency]
          @currency
        end

        def current_client
          if @spree_current_user.present?
            roles = @spree_current_user.spree_roles.map(&:name)
            if (roles.include? "client") || (roles.include? "sub_client")
              @client = @spree_current_user&.client
            elsif roles.include? "vendor"
              @client = @spree_current_user&.vendors&.first&.client
            end
          end
          @client
        end

        def storefront_current_client
          spree_current_store&.client
        end

        def require_spree_current_client
          raise CanCan::AccessDenied if current_client.nil?
        end

        def set_entity
          return unless [ "stores", "vendors" ].include?(controller_name)
          records = storefront_current_client.send(controller_name)
          instance_variable_set("@#{controller_name}", records)
        end

        def collection_options(collection)
          {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: resource_includes,
              fields: sparse_fields
          }
        end

        def valid_json?(json)
          begin
            JSON.parse(json)
            true
          rescue Exception => e
            false
          end
        end

        def serialize_resource(resource, serializer = Spree::V2::Storefront::PageSerializer)
          serializer.new(
            resource,
            include: resource_includes,
            sparse_fields: sparse_fields,
            params: {
              current_user: spree_current_user,
              locale: current_locale,
              price_options: current_price_options,
              store: current_store
            }
          ).serializable_hash
        end

        def serialize_collection(collection, serializer = Spree::V2::Storefront::GivexCardSerializer)
          serializer.new(
            collection,
            collection_options(collection)
          ).serializable_hash
        end

        def authorize_client_or_sub_client
          render json: { error: "You are not authorized to perform this action" } unless
            spree_current_user.has_spree_role?(:client) || spree_current_user.has_spree_role?(:sub_client) ||
            spree_current_user.has_spree_role?(:fulfilment_super_admin) || spree_current_user.has_spree_role?(:fulfilment_admin) ||
            spree_current_user.has_spree_role?(:fulfilment_user)
        end
      end
    end
  end
end

::Spree::Api::V2::BaseController.prepend Spree::Api::V2::BaseControllerDecorator
