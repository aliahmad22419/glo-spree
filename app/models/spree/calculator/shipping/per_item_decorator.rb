module Spree::Calculator::Shipping::PerItemDecorator
  def self.prepended(base)
    base.preference :currency, :string, default: -> { Spree::Config[:currency] }
  end

  def compute_from_quantity(quantity)
    amount = preferred_amount
    amount = BigDecimal(preferred_amount) if preferred_amount.is_a?(String)

    amount * quantity
  end
end

::Spree::Calculator::Shipping::PerItem.prepend Spree::Calculator::Shipping::PerItemDecorator
