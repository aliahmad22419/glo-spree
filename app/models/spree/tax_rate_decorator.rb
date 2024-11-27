
module Spree
  module TaxRateDecorator
    def self.prepended(base)
      base.after_commit :update_product_currency_prices
      base.has_and_belongs_to_many :stores, class_name: 'Spree::Store'
    end
    private

    def update_product_currency_prices
      return unless !included_in_price && (saved_change_to_amount? || saved_change_to_tax_category_id)
      Searchkick.callbacks(:bulk) { client.products.where(tax_category_id: tax_category_id).each { |p| ProductPricesWorker.perform_async(p.id) } }
    end
  end
end

::Spree::TaxRate.prepend Spree::TaxRateDecorator unless ::Spree::TaxRate.ancestors.include?(Spree::TaxRateDecorator)
