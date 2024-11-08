class VendorProductsPricesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'vendor_products_price'

  def perform(id, options)
    markup = Spree::Markup.find id
    current_vendor = markup&.currency&.vendor
    return if current_vendor.blank?

    prev, curr = options
    prev ||= 0.0
    curr ||= 0.0

    pro_ids = current_vendor.products.ids
    Spree::ProductCurrencyPrice.where(product_id: pro_ids, to_currency: markup.name, from_currency: markup.currency.name)
    .update_all ["
       price = non_exchanged_price * ((price / (non_exchanged_price * (100 + #{prev}))) * (100 + #{curr})),
       sale_price = ((non_exchanged_price * sale_price) / price) * ((price / (non_exchanged_price * (100 + #{prev}))) * (100 + #{curr})),
       local_area_price = ((non_exchanged_price * local_area_price) / price) * ((price / (non_exchanged_price * (100 + #{prev}))) * (100 + #{curr})),
       wide_area_price = ((non_exchanged_price * wide_area_price) / price) * ((price / (non_exchanged_price * (100 + #{prev}))) * (100 + #{curr})),
       restricted_area_price = ((non_exchanged_price * restricted_area_price) / price) * ((price / (non_exchanged_price * (100 + #{prev}))) * (100 + #{curr}))
    "]
    current_vendor.reload
    current_vendor.products.each(&:flush_cache)
    Searchkick.callbacks(:bulk) { current_vendor.products.find_each(&:reindex) }
  end
end
