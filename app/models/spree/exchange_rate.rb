module Spree
  class ExchangeRate < Spree::Base
    after_commit :update_product_currency_prices, if: :saved_change_to_value?
    belongs_to :currency, class_name: 'Spree::Currency', optional: true
    after_commit :clear_cache

    private

    def clear_cache
      client_stores = (self&.currency&.client&.stores || self&.currency&.vendor&.client&.stores) || []
      client_stores&.each{|store| store.clear_store_cache()}
    end

    def update_product_currency_prices
      return unless self.currency.present? && self.currency.client.present?

      prev, curr = saved_changes["value"]
      curr ||= 0.0
      prev ||= 0.0

      BulkUpdateProductsPricesWorker.perform_async(self.currency.client.products.ids, { "currency" => self.name }) unless (curr - prev).zero?
    end
  end
end
