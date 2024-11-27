module Spree::Calculator::TieredPercentDecorator
  def compute(object)
    computed_amount = if !(object.try(:glo_promo) || object.try(:order).try(:glo_promo))
      object.amount
    elsif object.class == Spree::Order
      object.exchanged_prices[:item_total]
    elsif object.class == Spree::LineItem
      object.order.exchanged_prices[:item_total]
    else
      object.amount rescue 0
    end

    base, percent = preferred_tiers.sort.reverse.detect { |b, _| BigDecimal(computed_amount) >= BigDecimal(b) }
    percent = BigDecimal(percent) if percent.is_a?(String)
    (BigDecimal(computed_amount) * (percent || preferred_base_percent) / 100).round(2)
  end

end

::Spree::Calculator::TieredPercent.prepend Spree::Calculator::TieredPercentDecorator
