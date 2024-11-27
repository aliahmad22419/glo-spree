module Spree
  class Promotion
    module Actions
      module CreateAdjustmentDecorator
        def self.prepended(base)
          base.before_validation -> { self.calculator ||= Spree::Calculator::FlatPercentItemTotal.new }
        end
        ORDER_CALCULATORS = ['FlexiRate', 'FlatRate', 'TieredFlatRate', 'TieredPercent'] # RelatedProductDiscount

        def action_type
          ORDER_CALCULATORS.include?(self.calculator.type.demodulize) ? 'order' : "item"
        end

        def perform(options = {})
          send("perform_#{action_type}", options)
        end

        def perform_order(options = {})
          order = options[:order]

          create_unique_adjustment(order, order)
        end

        def perform_item(options = {})
          order     = options[:order]
          promotion = options[:promotion]

          create_unique_adjustments(order, order.line_items) do |line_item|
            promotion.line_item_actionable?(order, line_item) && promo_applicable?(line_item)
          end
        end

        def compute_amount(obj)
          obj.price_values
          if obj.class.name == "Spree::Order"
            compute_order_amount(obj)
          elsif obj.class.name == "Spree::LineItem"
            compute_item_amount(obj)
          end
        end

        def compute_order_amount(order)
          [order_total(order), compute(order)].min * -1
        end

        def compute_item_amount(line_item)
          return 0 unless promotion.line_item_actionable?(line_item.order, line_item)

          amounts = [line_item.amount, compute(line_item)]
          order   = line_item.order

          # Prevent negative order totals
          amounts << order.amount - order.adjustments.sum(:amount).abs if order.adjustments.any?

          amounts.min * -1
        end

        def order_total(order)
          order.item_total + order.ship_total - order.shipping_discount
        end
      end
    end
  end
end

Spree::Promotion::Actions::CreateAdjustment.prepend Spree::Promotion::Actions::CreateAdjustmentDecorator
