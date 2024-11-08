class LystFeedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'lyst_feed'

  def lyst_report(store, report)
	  headers = ["url_key","item_group_id","id","Title", "Description", "Availability", "Condition",
	             "Price", "Price_Including_Shipping","Currency", "Image_link (main image URL)", "Brand", "Additional_image_link",
	             "Product Type (product category)", "On Sale","Sale_price", "Sale_Price_Including_Delivery", "Sale Currency", "Store Link", "Product Color",
	             "Product Size", "Product Gender"]
	  file_path = "public/reports/#{store.name.parameterize}-lyst-feed-products.csv"
	  CSV.open(file_path, "wb") do |csv|
		  csv << headers
		  active_vendor_ids = store.client.vendors.active.select("id").pluck(:id)
		  active_products = store.products.untrashed.approved.in_stock_status.product_quantity_count.where(vendor_id: active_vendor_ids)
		  active_products.each do |pro|
			  vendor_currency = store.default_currency
			  prrice = pro.price_values(store.default_currency, store)
			  # prrice = pro.product_price(store.default_currency, store)
			  on_sale = pro.on_sale? ? "Yes" : "No"
			  base_image = pro&.images&.where(base_image: true)&.last
				addtional_images = pro&.images&.where(base_image: false)

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
			  categories_name = pro.taxons.select('name').map{|taxon| taxon.name.downcase}.uniq
			  if pro.variants.present?
				  pro.variants.each_with_index do |variant,index|

					  color_and_size = {color: "", size: "", gender: ""}
					  variant&.option_values&.each do |ov|
						  if ov.option_type.name.downcase == "colour"
							  color_and_size[:color] = ov.name
						  end
						  if ov.option_type.name.downcase.include?"size"
							  color_and_size[:size] = ov.name
						  end
					  end

					  if color_and_size[:color].blank?
						  property_id = pro.properties.where(name: "Colours")&.last&.id
						  colors = ""
						  if property_id.present?
							  colors = pro.product_properties.where(property_id: property_id).map(&:value).join(',')
						  end
						  color_and_size[:color] = colors
					  end

					  if (categories_name.include?'men') && (categories_name.include?'women')
						  color_and_size[:gender] = "unisex"
					  elsif categories_name.include?'men'
						  color_and_size[:gender] = "male"
					  elsif categories_name.include?'women'
						  color_and_size[:gender] = "female"
					  end
					  variant_peoduct_id = pro.sku.to_s + "-" + (index + 1).to_s

					  data_arry = [pro.slug, pro.sku.to_s,variant_peoduct_id ,  pro&.name, desc, (pro.stock_status ? "in stock" : "out of stock"), "new",
					               prrice[:price], prrice[:base_price], vendor_currency.to_s, base_image_url, pro&.vendor&.name, addtional_images_url.join(', '),
					               categories_name&.join(', '), on_sale, prrice[:sale_price].to_f.zero? ? "" : prrice[:sale_price] ,
                         prrice[:sale_price].to_f.zero? ? "" : prrice[:final_price],
					               vendor_currency.to_s, "https://" + store.url  + "/" + pro.slug,
					               color_and_size[:color], color_and_size[:size], color_and_size[:gender]]
					  csv << data_arry
				  end
			  else
				  data_arry = [pro.slug, pro.sku.to_s,pro.sku.to_s, pro&.name, desc, (pro.stock_status ? "in stock" : "out of stock"), "new",
				               prrice[:price], prrice[:base_price], vendor_currency.to_s, base_image_url, pro&.vendor&.name, addtional_images_url.join(', '),
				               categories_name.join(', '), on_sale, prrice[:sale_price].to_f.zero? ? "" : prrice[:sale_price] ,
                       prrice[:sale_price].to_f.zero? ? "" : prrice[:final_price],
				               vendor_currency.to_s, "https://" + store.url  + "/" + pro.slug, "", "",""]
				  csv << data_arry
			  end

		  end
	  end
	  file_name = "#{store.name.parameterize}-lyst-feed-products.csv"
	  report.save_csv_file(file_path, file_name)

	end

  def perform(store_id)
	  store = Spree::Store.find(store_id)
	  report = store.reports.where(feed_type: "lyst_feed")&.last
	  report = store.reports.create(feed_type: "lyst_feed") if report.blank?
	  lyst_report(store, report)
  end
end
