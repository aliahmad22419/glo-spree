class BulkUpdateProductsPricesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'client_products_price', retry: 3

  def perform(product_ids, options= {})
    product_ids.each { |product_id| SecondaryProductPricesWorker.perform_async(product_id, options) }
  end
end
