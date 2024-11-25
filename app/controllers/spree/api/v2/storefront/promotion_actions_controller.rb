module Spree
  module Api
    module V2
      module Storefront
        class PromotionActionsController < ::Spree::Api::V2::BaseController
          
          before_action :require_spree_current_user
          before_action :check_permissions
          before_action :set_promotion, only: [:index]
          before_action :set_promotion_action, only: [:update, :destroy]

          def update
            params[:promotion_action][:calculator_attributes].permit!
            params[:promotion_action][:promotion_action_line_items_attributes].permit!
            if @promotion_action.update(promotion_action_params)
              @promotion_action.calculator.update_attribute(:preferences, params[:promotion_action][:calculator_attributes].to_h.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}) if params[:promotion_action][:calculator_attributes].present?
              if params[:promotion_action][:promotion_action_line_items_attributes].present?
                if @promotion_action.promotion_action_line_items.present?
                  @promotion_action.promotion_action_line_items.first.update(params[:promotion_action][:promotion_action_line_items_attributes])
                else
                  line_item = @promotion_action.promotion_action_line_items.new(params[:promotion_action][:promotion_action_line_items_attributes])
                  line_item.save
                end
              end
              render_serialized_payload { serialize_resource(@promotion_action)  }
            else
              render_error_payload(failure(@promotion_action).error)
            end
          end

          def create
            promotion_action = Spree::PromotionAction.new(promotion_action_params)
            if promotion_action.save
              render_serialized_payload { serialize_resource(promotion_action)  }
            else
              render_error_payload(failure(promotion_action).error)
            end
          end

          def destroy
            if @promotion_action.destroy
              render_serialized_payload { serialize_resource(@promotion_action) }
            else
              render_error_payload(failure(@promotion_action).error)
            end
          end

          private

          def serialize_resource(resource)
            Spree::V2::Storefront::PromotionActionSerializer.new(resource).serializable_hash
          end

          def set_promotion
            @promotion = current_client.promotions.find_by('spree_promotions.id = ?', params[:promotion_id])
          end

          def set_promotion_action
            @promotion_action = Spree::PromotionAction.find_by('spree_promotion_actions.id = ?', params[:id])
          end

          def promotion_action_params
            params.require(:promotion_action).permit(:type, :promotion_id, :calculator_type, :exclude_sale_items, preferences: {})
          end

        end
      end
    end
  end
end
