module Spree
  module Api
    module V2
      module Storefront
        class RedirectsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :if => Proc.new{ params[:access_token] }
          before_action :set_store, except: [:show, :update, :destroy]
          before_action :set_route, only: [:show, :update, :destroy]
          before_action :check_permissions

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            routes = @store.redirects.accessible_by(current_ability, :index).ransack(params[:q]).result
            routes = collection_paginator.new(routes, params).call

            render_serialized_payload { serialize_route_collection(routes) }
          end

          def show
            authorize! :show, @route
            render_serialized_payload { serialize_resource(@route) }
          end

          def update
            authorize! :update, @route
            if @route.update(route_params)
              render_serialized_payload { serialize_resource(@route) }
            else
              render_error_payload(failure(@route).error)
            end
          end

          def create
            route = @store.redirects.new(route_params)
            authorize! :create, route
            if route.save
              render_serialized_payload { serialize_resource(route) }
            else
              render_error_payload(failure(route).error)
            end
          end

          def destroy
            authorize! :destroy, @route
            if @route.destroy
              render_serialized_payload { serialize_resource(@route) }
            else
              render_error_payload(failure(@route).error)
            end
          end

          private

          def set_store
            @store = current_client.stores.find_by('spree_stores.id = ?', params[:store_id])
          end

          def set_route
            @route = Spree::Redirect.find_by('spree_redirects.id = ?', params[:id])
            return render json: { error: "Route not found" }, status: 403 unless @route
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::RedirectSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def serialize_route_collection(collection)
            Spree::V2::Storefront::RedirectSerializer.new(collection,
            collection_options(collection)).serializable_hash
          end

          def route_params
            params.require(:route).permit(:type_redirect, :from, :to)
          end
        end
      end
    end
  end
end
