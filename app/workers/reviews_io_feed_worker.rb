class ReviewsIoFeedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'reviews_io_feed'

  def reviews_io_report(store, report)
    reports_path = "public/reports"
    Dir.mkdir("#{reports_path}") unless Dir.exist?("#{reports_path}")
    headers = ["SKU", "Product Name", "Product Image URL", "Product Page URL", "Brand"]
    file_path = "public/reports/#{store.name.parameterize}-reviews-io-products-feed.csv"
    CSV.open(file_path, "wb") do |csv|
      csv << headers
      active_vendor_ids = store.client.vendors.active.ids
      active_products = store.products.untrashed.approved.in_stock_status.product_quantity_count.where(vendor_id: active_vendor_ids)
      active_products.find_each do |product|
        image_url = ""
        image = product.images.where(base_image: true).last
        image ||= product.images.where(base_image: false).first
        image_url = store&.active_storge_url(image.attachment) if image.present?
        product_url = "https://" + store.url  + "/" + product.slug

        data_arry = [product.sku, product.name, image_url, product_url, product.vendor&.name]
        csv << data_arry
      end
    end
    file_name = "#{store.name.parameterize}-reviews-io-products-feed.csv"
    report.save_csv_file(file_path, file_name)
  end

  def perform(store_id)
    store = Spree::Store.find(store_id)
    report = store.reports.where(feed_type: "reviews_io_feed").last
    report = store.reports.create(feed_type: "reviews_io_feed") if report.blank?
    reviews_io_report(store, report)
  end
end
