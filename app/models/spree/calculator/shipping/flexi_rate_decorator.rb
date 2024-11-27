module Spree::Calculator::Shipping::FlexiRateDecorator
  def self.prepended(base)
    base.preference :currency, :string, default: -> { Spree::Config[:currency] }
  end
end

::Spree::Calculator::Shipping::FlexiRate.prepend Spree::Calculator::Shipping::FlexiRateDecorator
