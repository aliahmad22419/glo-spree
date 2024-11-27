# A rule to apply to an order greater than (or greater than or equal to)
# a specific amount
module Spree
  class Promotion
    module Rules
      module ItemTotalDecorator
        def self.prepended(base)
          # Override symbol and use lebel (gt, lt instead of >, <)
          base.preference :operator_min, :string, default: 'gt'
          base.preference :operator_max, :string, default: 'lt'
        end

        def eligible?(order, _options = {})
          item_total = BigDecimal(order.price_values(order.currency)[:prices][:item_total])

          lower_limit_condition = item_total.send(preferred_operator_min == 'gte' ? :>= : :>, BigDecimal(preferred_amount_min.to_s))
          upper_limit_condition = item_total.send(preferred_operator_max == 'lte' ? :<= : :<, BigDecimal(preferred_amount_max.to_s))

          eligibility_errors.add(:base, ineligible_message_max) unless upper_limit_condition
          eligibility_errors.add(:base, ineligible_message_min) unless lower_limit_condition

          eligibility_errors.empty?
        end
      end
    end
  end
end

::Spree::Promotion::Rules::ItemTotal.prepend Spree::Promotion::Rules::ItemTotalDecorator
