module Spree
  module OrderUpdaterDecorator
    # def recalculate_adjustments
    #   all_adjustments.includes(:adjustable).map(&:adjustable).uniq.each do |adjustable|
    #     Adjustable::AdjustmentsUpdater.update(adjustable)
    #   end
    # end

    # give each of the shipments a chance to update themselves
    # def update_shipments
    #   shipping_method_filter = order.completed? ? ShippingMethod::DISPLAY_ON_BACK_END : ShippingMethod::DISPLAY_ON_FRONT_END
    #
    #   shipments.each do |shipment|
    #     next unless shipment.persisted?
    #
    #     shipment.update!(order)
    #     shipment.refresh_rates(shipping_method_filter)
    #     shipment.update_amounts
    #   end
    # end

    # alias_method :float_tp, :truncated_amount_to_float Exchangeable Module
    def rounded amount
      order.float_tp(amount)
    end

    def update_payment_total
      p_total = payments.completed.includes(:refunds).inject(0) { |sum, payment| sum + payment.amount - payment.refunds.sum(:amount) }
      order.payment_total = rounded(p_total)
    end

    def update_shipment_total
      order.shipment_total = shipments.sum{ |s| rounded(s.cost) }
      update_order_total
    end

    def update_adjustment_total
      recalculate_adjustments
      order.adjustment_total = line_items.sum{ |li| rounded(li.adjustment_total) } +
        shipments.sum{ |s| rounded(s.adjustment_total) } +
        adjustments.eligible.sum { |a| rounded(a.amount) }
      order.included_tax_total = line_items.sum{ |li| rounded(li.included_tax_total) } + shipments.sum{ |s| rounded(s.included_tax_total) }
      order.additional_tax_total = line_items.sum{ |li| rounded(li.additional_tax_total) } + shipments.sum{ |s| rounded(s.additional_tax_total) }

      order.promo_total = line_items.sum{ |li| rounded(li.promo_total) } +
        shipments.sum{ |s| rounded(s.promo_total) } +
        adjustments.promotion.eligible.sum{ |p| rounded(p.amount) }

      update_order_total
    end

    def update_item_total
      order.item_total = line_items.sum('sub_total * quantity')
      update_order_total
    end
  end
end
::Spree::OrderUpdater.prepend Spree::OrderUpdaterDecorator if ::Spree::OrderUpdater.included_modules.exclude?(Spree::OrderUpdaterDecorator)
