module Spree
  module MoneyDecorator
    def initialize(amount, options = {})
      use_default_currency
      @money   = Monetize.parse([amount, (options[:currency] || Spree::Config[:currency])].join)
      @options = Spree::Money.default_formatting_rules.merge(options)
    end

    def use_default_currency
      currency = Spree::Config[:currency]
      ::Money.default_currency = currency
    end
  end
end

Spree::Money.prepend Spree::MoneyDecorator
