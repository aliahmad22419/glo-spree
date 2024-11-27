
module Spree
  module PromotionDecorator
    def activate(payload)
      order = payload[:order]
      return unless self.class.order_activatable?(order)

      payload[:promotion] = self
      # OVERRIDEN
      action = actions[0]
      results = action.perform(payload) if action
      action_taken = [results].include?(true)
      if action_taken
        # connect to the order
        # create the join_table entry.
        orders << order
        save
      end
      action_taken
    end

    def deactivate(payload)
      order = payload[:order]
      return unless self.class.order_activatable?(order)

      payload[:promotion] = self
      # OVERRIDEN
      action = actions[0]
      results = action.revert(payload) if action&.respond_to?(:revert)
      action_taken = [results].include?(true)

      if action_taken
        # connect to the order
        # create the join_table entry.
        orders << order
        save
      end
      action_taken
    end

    def shipment_actionable?(order, shipment)
      if eligible? order
        specific_rule = rules.where(type: "Spree::Promotion::Rules::ShipmentProductsTotal")
                              .select { |rule| rule.applicable?(order) && rule.eligible?(order, {}) }
                              .first

        return true if specific_rule.blank?

        specific_rule.actionable? shipment
      else
        false
      end
    end
  end
end

::Spree::Promotion.prepend Spree::PromotionDecorator
