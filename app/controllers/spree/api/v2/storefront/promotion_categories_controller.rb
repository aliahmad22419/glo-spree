module Spree
  module Api
    module V2
      module Storefront
        class PromotionCategoriesController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :set_promotion_category, only: [:show, :update, :destroy]
					before_action :check_permissions

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            promotion_categories = current_client.promotion_categories
            q = promotion_categories.ransack(params[:q])
            promotion_categories = q.result.order("id DESC")
            promotion_categories = collection_paginator.new(promotion_categories, params).call
            render_serialized_payload { serialize_collection(promotion_categories) }
          end

          def show
            render_serialized_payload { serialize_resource(@promotion_category) }
          end

          def update
            if @promotion_category.update(promotion_category_params)
              render_serialized_payload { serialize_resource(@promotion_category) }
            else
              render_error_payload(failure(@promotion_category).error)
            end
          end

          def create
            promotion_category = current_client.promotion_categories.new(promotion_category_params)
              if promotion_category.save
                render_serialized_payload { serialize_resource(promotion_category) }
              else
                render_error_payload(failure(promotion_category).error)
              end
          end

          def destroy
            if @promotion_category.destroy
              render_serialized_payload { serialize_resource(@promotion_category) }
            else
              render_error_payload(failure(@promotion_category).error)
            end
          end

          def destroy_multiple
            promotion_categories = Spree::PromotionCategory.accessible_by(current_ability, :index)
                                                           .where('spree_promotion_categories.id IN (?)', JSON.parse(params[:ids]))
            if promotion_categories.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(promotion_categories).error)
            end
          end

          private
          def serialize_collection(collection)
            Spree::V2::Storefront::PromotionCategorySerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::PromotionCategorySerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_promotion_category
            @promotion_category = Spree::PromotionCategory.accessible_by(current_ability, :show).find_by('spree_promotion_categories.id = ?', params[:id])
          end

          def promotion_category_params
            params.require(:promotion_category).permit(:name, :code)
          end

        end
      end
    end
  end
end
