module Spree::Calculator::PriceSackDecorator
  def self.prepended(base)
    base.preference :currency, :string, default: -> { Spree::Config[:currency] }
  end
end

::Spree::Calculator::PriceSack.prepend Spree::Calculator::PriceSackDecorator
