module Spree::Calculator::TieredFlatRateDecorator
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

    base, discount = preferred_tiers.sort.reverse.detect { |b, _| BigDecimal(computed_amount) >= BigDecimal(b) }
    discount = BigDecimal(discount) if discount.is_a?(String)
    discount || preferred_base_amount
  end
end


::Spree::Calculator::TieredFlatRate.prepend Spree::Calculator::TieredFlatRateDecorator
