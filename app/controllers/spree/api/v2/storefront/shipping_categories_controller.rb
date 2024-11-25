module Spree
  module Api
    module V2
      module Storefront
        class ShippingCategoriesController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :set_shipping_category, only: [:show, :update, :destroy]
          before_action :check_permissions


          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            shipping_categories = Spree::ShippingCategory.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
            shipping_categories = collection_paginator.new(shipping_categories, params).call
            render_serialized_payload { serialize_collection(shipping_categories) }
          end

          def show
            render_serialized_payload { serialize_resource(@shipping_categories) }
          end

          def update
            if @shipping_categories.update(shipping_categories_params)
              render_serialized_payload { serialize_resource(@shipping_categories) }
            else
              render_error_payload(failure(@shipping_categories).error)
            end
          end

          def create
            authorize! :create, Spree::ShippingCategory
            shipping_categories = current_client.shipping_categories.new(shipping_categories_params)
            if shipping_categories.save
              render_serialized_payload { serialize_resource(shipping_categories) }
            else
              render_error_payload(failure(shipping_categories).error)
            end
          end

          def destroy
            if @shipping_categories.destroy
              render_serialized_payload { serialize_resource(@shipping_categories) }
            else
              render_error_payload(failure(@shipping_categories).error)
            end
          end

          def destroy_multiple
            shipping_categories = Spree::ShippingCategory.accessible_by(current_ability)
                                                         .where('spree_shipping_categories.id IN (?)', JSON.parse(params[:ids]))
            if shipping_categories.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(shipping_categories).error)
            end
          end

          private
          def serialize_collection(collection)
            Spree::V2::Storefront::ShippingCategoriesSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::ShippingCategoriesSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_shipping_category
            @shipping_categories = Spree::ShippingCategory.accessible_by(current_ability).find_by('spree_shipping_categories.id = ?', params[:id])
            return render json: { error: "Shipping Category not found" }, status: 403 unless @shipping_categories
          end

          def shipping_categories_params
            params.require(:shipping_category).permit(:name,:is_weighted)
          end

        end
      end
    end
  end
end
