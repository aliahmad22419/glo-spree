class BatchProductsImageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'batch_crud'

  def perform(batch_id)
    @product_batch = ProductBatch.find(batch_id)
    attach_images
  end

  def attach_images
    @product_batch.stock_products.find_each do |stock_product|
      @product_batch.product.images.find_each do |image|
        image.duplicate(stock_product.master)
      end
    end
  end
end
