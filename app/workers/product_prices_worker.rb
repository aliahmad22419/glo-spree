class ProductPricesWorker < CurrencyPriceWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'product_prices', retry: 3

  def perform(id, options = {})
    update_prices(id, options)
  end
end
