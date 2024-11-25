module Spree
  module Api
    module V2
      module Storefront
        class PromotionsController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :check_permissions
          before_action :set_promotion, only: [:show, :update, :destroy]


          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            promotions = Spree::Promotion.accessible_by(current_ability, :index).includes(:promotion_rules, :promotion_actions, client: [:users, :taxons, products: :variants]).ransack(params[:q]).result.order("id DESC")
            promotions = collection_paginator.new(promotions, params).call
            render_serialized_payload { serialize_collection(promotions) }
          end

          def show
            render_serialized_payload { serialize_resource(@promotion) }
          end

          def update
            if @promotion.update(promotion_params.merge({ generate_code: params[:generate_code] }))
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@promotion).error)
            end
          end

          def create
            authorize! :create, Spree::Promotion
            promotion = current_client.promotions.new(promotion_params.merge({ generate_code: params[:generate_code] }))
            if promotion.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(promotion).error)
            end
          end

          def destroy
            if @promotion.destroy
              render_serialized_payload { serialize_resource(@promotion) }
            else
              render_error_payload(failure(@promotion).error)
            end
          end

          def destroy_multiple
            promotions = Spree::Promotion.accessible_by(current_ability, :index).where('spree_promotions.id IN (?)', JSON.parse(params[:ids]))
            if promotions.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(promotions).error)
            end
          end

          def form_data
            data = {}
            data["promotion_categories"] = current_client.promotion_categories.order(:name).select(:id, :name)
            render json: data.to_json
          end

          private

          def serialize_collection(collection)
            Spree::V2::Storefront::PromotionSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def collection_options(collection)
            {
                links: collection_links(collection),
                meta: collection_meta(collection),
                include: resource_includes,
                fields: sparse_fields
            }
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::PromotionSerializer.new(resource).serializable_hash
          end

          def set_promotion
            @promotion = Spree::Promotion.accessible_by(current_ability, :show).includes(:promotion_rules, :promotion_actions, client: [:users, :taxons, products: :variants]).find_by('spree_promotions.id = ?', params[:id])
          end

          def promotion_params
            params.require(:promotion).permit(:name, :description, :expires_at, :starts_at, :type, :usage_limit,
            :match_policy, :code, :advertise, :path, :promotion_category_id)
          end

        end
      end
    end
  end
end
