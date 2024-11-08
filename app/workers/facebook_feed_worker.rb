class FacebookFeedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'facebook_feed'

  def facebook_report(store, report)
	  headers = ["id","title", "description", "availability", "condition",
	             "price", "image_link", "brand", "additional_image_link", "variations",
	             "product_type","sale_price", "link", "inventory", "custom_label_0"]
	  file_path = "public/reports/#{store.name.parameterize}-facebook-feed-products.csv"
	  CSV.open(file_path, "wb") do |csv|
		  csv << headers
		  active_vendor_ids = store.client.vendors.active.select("id").pluck(:id)
		  active_products = store.products.untrashed.approved.in_stock_status.product_quantity_count.where(vendor_id: active_vendor_ids)
		  active_products.each do |pro|
			  vendor_currency = store.default_currency
			  prrice = pro.price_values(store.default_currency, store)
			  on_sale = pro.on_sale? ? "Yes" : "No"
			  base_image = pro&.images&.where(base_image: true)&.last
			  addtional_images = pro&.images&.where(base_image: false)
			  custom_label_0 = pro&.vendor_sku
			  inventory = pro&.count_on_hand
			  addtional_images_url = []
			  if addtional_images
				  addtional_images.each do |img|
					  image_url = store&.active_storge_url(img.attachment)
					  addtional_images_url.push image_url
				  end
			  end

			  base_image_url = ""
			  if base_image
				  base_image_url = store&.active_storge_url(base_image.attachment)
			  else
				  if addtional_images_url.present?
					  base_image_url = addtional_images_url.first
					  addtional_images_url.delete_at(0)
				  end
			  end
			  # stores_urls = []
			  # client.stores.each do |store|
			  # 	if pro&.stores&.include?store
			  # 		stores_urls.push(store.url  + "/" + pro.slug)
			  # 	else
			  # 		stores_urls.push("")
			  # 	end
			  # end
			  # store_base_urls = stores_urls.join(', ')
			  desc =  ActionView::Base.full_sanitizer.sanitize(pro.description)
			  property_id = pro.properties.where(name: "Product Types")&.last&.id
			  types = ""
			  if property_id.present?
				  types = pro.product_properties.where(property_id: property_id).map(&:value).join(',')
			  end

			  price_and_currency = prrice[:price].to_s + " " + vendor_currency.to_s
			  product_url = "https://" + store.url  + "/" + pro.slug

			  data_arry = [(pro.sku.to_s + ""),pro&.name, desc, (pro.stock_status ? "in stock" : "out of stock"), "new",
			               price_and_currency, base_image_url, pro&.vendor&.name, addtional_images_url.join(', '),
			               pro&.variants&.map{|v| v.options_text}&.join(', '),
			               types,
			               prrice[:sale_price].to_f.zero? ? "" : (prrice[:sale_price].to_s + " " +vendor_currency.to_s) ,
			               product_url, inventory, custom_label_0]
			  csv << data_arry
		  end
	  end
	  file_name = "#{store.name.parameterize}-facebook-feed-products.csv"
	  report.save_csv_file(file_path, file_name)
	end

  def perform(store_id)
	  store = Spree::Store.find(store_id)
	  report = store.reports.where(feed_type: "facebook_feed")&.last
	  report = store.reports.create(feed_type: "facebook_feed") if report.blank?
	  facebook_report(store, report)
  end
end
