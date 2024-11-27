module Spree::Calculator::Shipping::FlatRateDecorator
  def self.prepended(base)
    base.preference :currency, :string, default: -> { Spree::Config[:currency] }

  end
end

::Spree::Calculator::Shipping::FlatRate.prepend Spree::Calculator::Shipping::FlatRateDecorator
