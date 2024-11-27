module Spree
  class Currency < Spree::Base
    scope :with_out_vendor_currencies, -> { where("vendor_id IS NULL") }
    after_commit :update_product_currency_prices
    has_many :exchange_rates, dependent: :destroy, class_name: 'Spree::ExchangeRate'
    has_many :markups, dependent: :destroy, class_name: 'Spree::Markup'
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    def self.with_code
      ::Money::Currency.table.each_with_object({}) do |curr, hash|
        code = curr[1][:iso_code].to_s
        hash[code] = Spree::Money.new(code).currency.symbol
      end
    end

    private

    def update_product_currency_prices
      return unless vendor.present?
      BaseCurrencyPricesWorker.perform_async(vendor_id)
    end
  end
end
