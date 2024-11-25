module Spree
  module Api
    module V2
      module Storefront
        class PromotionRulesController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :check_permissions
          before_action :set_promotion, only: [:index, :create, :update]
          before_action :set_promotion_rule, only: [:show, :update, :destroy]

          def update
            if @promotion_rule.update(promotion_rule_params)
              @promotion.update_attribute(:match_policy, params[:promotion_rule][:match_policy]) unless @promotion.match_policy.eql?(params[:promotion_rule][:match_policy])
              render_serialized_payload { serialize_resource(@promotion_rule) }
            else
              render_error_payload(failure(@promotion_rule).error)
            end
          end

          def create
            promotion_rule = Spree::PromotionRule.new(promotion_rule_params)
            if promotion_rule.save
              @promotion.update_attribute(:match_policy, params[:match_policy]) unless @promotion.match_policy.eql?(params[:match_policy])
              render_serialized_payload { serialize_resource(promotion_rule)  }
            else
              render_error_payload(failure(promotion_rule).error)
            end
          end

          def destroy
            if @promotion_rule.destroy
              render_serialized_payload { serialize_resource(@promotion_rule) }
            else
              render_error_payload(failure(@promotion_rule).error)
            end
          end

          private

          def serialize_resource(resource)
            Spree::V2::Storefront::PromotionRuleSerializer.new(resource).serializable_hash
          end

          def set_promotion
            @promotion = current_client.promotions.find_by('spree_promotions.id = ?', params[:promotion_id])
          end

          def set_promotion_rule
            @promotion_rule = Spree::PromotionRule.find_by('spree_promotion_rules.id = ?', params[:id])
          end

          def promotion_rule_params
            params.require(:promotion_rule).permit(:type, :preferences, :promotion_id, :user_id, :code, :preferred_operator_min,
                                                   :preferred_operator_max, :preferred_amount_min, :preferred_amount_max,
                                                   :product_ids_string, :preferred_match_policy, :preferred_country_id,
                                                   :user_ids_string, :taxon_ids_string, preferred_product_type_limits: [:amount_min, :product_type])
          end

        end
      end
    end
  end
end
