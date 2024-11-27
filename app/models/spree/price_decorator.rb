
module Spree
  module PriceDecorator
    def self.prepended(base)
      base.after_commit :update_product_currency_prices, if: :saved_change_to_amount?
    end

    private

    def update_product_currency_prices
      prev, curr = saved_changes["amount"]
      curr ||= 0.0
      prev ||= 0.0
      ProductPricesWorker.perform_async(variant.product_id) unless (curr - prev).zero?
    end

    def ensure_currency
      self.currency ||= Spree::Config[:currency]
    end
  end
end

::Spree::Price.prepend Spree::PriceDecorator if ::Spree::Price.included_modules.exclude?(Spree::PriceDecorator)
