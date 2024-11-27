module Spree::Calculator::Shipping::PriceSackDecorator
  def self.prepended(base)
    base.preference :currency, :string, default: -> { Spree::Config[:currency] }
  end

  def compute_package(package)
    compute_from_price(package.contents.sum{ |c| c.line_item.amount })
  end

  def compute_from_price(price)
    minimal_amount = self.preferred_minimal_amount
    minimal_amount = BigDecimal(minimal_amount) if minimal_amount.is_a?(String)
    normal_amount = self.preferred_normal_amount
    normal_amount = BigDecimal(normal_amount) if normal_amount.is_a?(String)
    discount_amount = self.preferred_discount_amount
    discount_amount = BigDecimal(discount_amount) if discount_amount.is_a?(String)

    if price < minimal_amount
      normal_amount
    else
      discount_amount
    end
  end
end

::Spree::Calculator::Shipping::PriceSack.prepend Spree::Calculator::Shipping::PriceSackDecorator
