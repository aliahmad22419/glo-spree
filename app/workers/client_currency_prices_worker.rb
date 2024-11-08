# Creating bulk exchange rates and update products for client's supported currencies
class ClientCurrencyPricesWorker < CurrencyPriceWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'client_currency_prices', retry: 3

  def perform(id, bulk_exchange_rates, options = {})
    client = Spree::Client.find(id)

    Spree::ExchangeRate.insert_all(bulk_exchange_rates)
    BulkUpdateProductsPricesWorker.perform_async(client.products.ids)
  end
end

