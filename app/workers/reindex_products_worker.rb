class ReindexProductsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'reindex_es_products'

  def perform(ids)
    products = Spree::Product.where id: ids
    Searchkick.callbacks(:bulk) { products.reindex }
  end
end
