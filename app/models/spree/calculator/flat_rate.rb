require_dependency 'spree/calculator'

# Calculations are independent of currency
module Spree
  class Calculator::FlatRate < Calculator
    preference :amount, :decimal, default: 0
    # preference :currency, :string, default: -> { Spree::Config[:currency] }
    preference :currency, :string, default: -> { Spree::Config[:currency] }

    def self.description
      Spree.t(:flat_rate_per_order)
    end

    def compute(object = nil)
      # if object && preferred_currency.casecmp(object.currency.upcase).zero?
      (object.present? ? preferred_amount : 0)
    end
  end
end
