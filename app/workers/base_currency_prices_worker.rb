class BaseCurrencyPricesWorker < CurrencyPriceWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'base_currency_products_price', retry: 3

  def perform(id)
    current_vendor = Spree::Vendor.find_by_id id
    return if current_vendor.blank?
    Searchkick.callbacks(:bulk) { current_vendor.products.find_each { |product| SecondaryProductPricesWorker.perform_async(product.id) } }
  end
end
