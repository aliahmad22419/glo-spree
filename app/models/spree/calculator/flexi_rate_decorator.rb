module Spree::Calculator::FlexiRateDecorator
  def self.prepended(base)
    base.preference :currency, :string,  default: -> { Spree::Config[:currency] }
  end
end

::Spree::Calculator::FlexiRate.prepend(Spree::Calculator::FlexiRateDecorator)
