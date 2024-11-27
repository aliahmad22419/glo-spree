module Spree::Calculator::Shipping::DigitalDeliveryDecorator
  def self.prepended(base)
    base.preference :currency, :string, default: -> { Spree::Config[:currency] }
  end
end
::Spree::Calculator::Shipping::DigitalDelivery.prepend Spree::Calculator::Shipping::DigitalDeliveryDecorator
