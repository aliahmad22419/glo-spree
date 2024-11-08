class ExpiredSaleProductsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'expired_sale_products'

  def perform()
    # Expire sale with sale end in past
    Searchkick.callbacks(:bulk) {
      Spree::Product.expired_sale_products.find_each{ |product| product.update(on_sale: false) }
    }

    # Update currency prices for products with sale starting from today
    Searchkick.callbacks(:bulk) {
      Spree::Product.sale_start_today.find_each{ |product| product.send(:update_product_currency_prices) }
    }
  end
end
