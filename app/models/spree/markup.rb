module Spree
  class Markup < Spree::Base
    after_commit :update_product_currency_prices, if: :saved_change_to_value?
    belongs_to :currency, class_name: 'Spree::Currency', optional: true

    private

    def update_product_currency_prices
      return unless currency.present?
      prev, curr = saved_changes["value"]
      curr ||= 0.0
      prev ||= 0.0
      VendorProductsPricesWorker.perform_async(id, saved_changes["value"]) unless (curr - prev).zero?
    end
  end
end
