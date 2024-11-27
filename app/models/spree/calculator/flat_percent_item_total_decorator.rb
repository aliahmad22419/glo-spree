module Spree::Calculator::FlatPercentItemTotalDecorator
  def compute(object)
    computed_amount = object.amount
    computed_amount = object.exchanged_prices[:item_total].to_f if object.class == Spree::Order && object.glo_promo

    discount = (computed_amount * preferred_flat_percent / 100).round(2)

    # We don't want to cause the promotion adjustments to push the order into a negative total.
    if discount > computed_amount
      computed_amount
    else
      discount
    end
  end
end

::Spree::Calculator::FlatPercentItemTotal.prepend Spree::Calculator::FlatPercentItemTotalDecorator
