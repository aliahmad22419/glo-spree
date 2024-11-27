module Spree
  module ClientDecorator
    def self.prepended(base)
			base.preference :enable_auto_exchange_rates, :boolean, default: false
			base.preference :exchange_rates_schedule, :string, default: 'once_day'
			base.preference :exchange_rates_updated_at, :string, default: nil
			base.preference :vendor_agreement_text, :text, default: 'Agreed to client terms?'

			base.self.whitelisted_ransackable_attributes = %w[name email]

			base.after_create :create_taxonomies, :create_tags, :assign_personas

			base.has_many :json_files, dependent: :destroy, :class_name => 'Spree::JsonFile'
			base.belongs_to :client_address, foreign_key: :client_address_id, class_name: 'Spree::Address',optional: true
			base.has_one_attached :logo
			base.has_many :givex_cards, class_name: "Spree::GivexCard"

			# has_attached_file :logo,
			# 									styles: { mini: '48x48>', small: '100x100>', medium: '250x250>' },
			# 									default_style: :medium,
			# 									url:  '/clients/:id/:style/:filename',
			# 									path: ':rails_root/public/clients/:id/:style/:filename',
			# 									convert_options: { all: '-strip -auto-orient' }
			#
			# validates_attachment_file_name :logo, matches: [/png\Z/i, /jpe?g\Z/i], if: -> { logo.present? }
			base.has_many :embed_widgets, dependent: :destroy, :class_name => 'Spree::EmbedWidget'
			base.has_many :product_currency_prices, dependent: :destroy, :class_name => 'Spree::ProductCurrencyPrice'

			base.accepts_nested_attributes_for :embed_widgets, allow_destroy: true

			base.has_many :notifications, dependent: :destroy, :class_name => 'Spree::Notification'

			base.has_one :master_vendor, -> { where(master: true) }, class_name: 'Spree::Vendor'
			base.has_one :pickup_shipping, -> { where(delivery_mode: "pickup") }, class_name: 'Spree::ShippingMethod'
			base.has_one :delivery_shipping, -> { where(delivery_mode: "delivery") }, class_name: 'Spree::ShippingMethod'

			base.has_many :galleries, dependent: :destroy, :class_name => 'Spree::Gallery'
			base.has_many :order_tags, dependent: :destroy, :class_name => 'Spree::OrderTag'
			base.has_many :tags, dependent: :destroy, :class_name => 'Spree::Tag'
			base.has_many :givex_cards, dependent: :destroy, class_name: 'Spree::GivexCard'
			base.has_many :scheduled_reports, as: :reportable, class_name: 'ScheduledReport', dependent: :destroy
			base.accepts_nested_attributes_for :scheduled_reports, allow_destroy: true
			base.has_one :email_template, dependent: :destroy, :class_name => 'Spree::EmailTemplate'
			base.has_many :bulk_orders, class_name: 'Spree::BulkOrder'
			base.has_many :whitelist_emails, dependent: :destroy, class_name: 'Spree::WhitelistEmail'
			has_and_base.belongs_to_many :service_login_sub_admins, class_name: 'Spree::ServiceLoginUser', join_table: 'spree_clients_service_login', foreign_key: 'client_id', association_foreign_key: 'service_login_sub_admin_id'
			base.has_many :personas, class_name: 'Spree::Persona'

			base.has_many :aws_files, dependent: :destroy, class_name: 'Spree::AwsFile'
			base.after_commit :ensure_base_currency, :update_product_currency_prices, if: :saved_change_to_supported_currencies?
			base.after_commit :update_scheduled_reports_cron, if: :saved_change_to_timezone?
			base.after_update :create_product, if: -> {multi_vendor_store_previously_changed? && multi_vendor_store && stores&.last.fast_track?}
    end

		for source in Spree::JsonFile::SOURCES do
			define_method "#{source.downcase.gsub(/-/, '_')}_json" do
				file = json_files.find_by(source: source.downcase)

				return file&.content&.blob&.download
			end
		end

		def update_product_currency_prices
			prev, curr = self.saved_changes["supported_currencies"]
			options = { "ids" => self.products.ids, "supported_currencies" => (curr - prev) }

			UpdateSupportedCurrencyExchangesWorker.perform_async(self.id, options)
		end

		def create_taxonomies
		taxonomy = taxonomies.create(name: "Categories")
		taxonomy.taxons.create(name: "her", parent_id: taxonomy.taxons.first.id, description: "her",meta_title: 'her', meta_description: 'her')
		taxonomy.taxons.create(name: "his", parent_id: taxonomy.taxons.first.id, description: "his",meta_title: 'his', meta_description: 'his')
		end

		def self.to_csv(store)
			headers = ["id (SKU)","Title", "Description", "Availability", "Condition",
																	"Price", "Image_link (main image URL)", "Brand", "Additional_image_link", "Variants",
																	"Product_type (product category)", "Sale_price", "Store Link"]
			CSV.generate(headers: true) do |csv|
				csv << headers
				active_vendor_ids = store.client.vendors.active.select("id").pluck(:id)
				active_products = store.products.untrashed.approved.in_stock_status.product_quantity_count.where(vendor_id: active_vendor_ids)
				active_products.each do |pro|
					vendor_currency = store.default_currency
					prrice = pro.product_price(store.default_currency, store)
					on_sale = pro.on_sale? ? "Yes" : "No"
					base_image = pro&.images&.where(base_image: true)&.last
					base_image_url = ""
					if base_image
						base_image_url = store.url + "/" + base_image.styles[3][:url]
					end
					addtional_images = Spree::Image.where(viewable: pro.variants_including_master, base_image: false)
					addtional_images_url = []
					if addtional_images
						addtional_images.each do |img|
							image_url = store.url + "/"  + img.styles[3][:url]
							addtional_images_url.push image_url
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

					data_arry = [pro.slug, pro&.name, pro.description, (pro.stock_status ? "in stock" : "out of stock"), "new",
												prrice, vendor_currency.to_s, base_image_url, pro&.vendor&.name, addtional_images_url.join(', '), pro&.variants&.map{|v| v.options_text}&.join(', '),
												pro&.taxons&.map(&:name)&.join(', '), on_sale, pro.on_sale? ? prrice : "" , vendor_currency.to_s, store.url  + "/" + pro.slug]
					csv << data_arry
				end
			end

		end

		def self.product_csv(store)
			headers = ["url_key","item_group_id","id","Title", "Description", "Availability", "Condition",
								"Price", "Price_Including_Shipping","Currency", "Image_link (main image URL)", "Brand", "Additional_image_link",
								"Product Type (product category)", "On Sale","Sale_price", "Sale Currency", "Store Link", "Product Color",
								"Product Size", "Product Gender"]
			CSV.open("public/najl_products.csv", "wb") do |csv|
				csv << headers
				active_vendor_ids = store.client.vendors.active.select("id").pluck(:id)
				active_products = store.products.untrashed.approved.in_stock_status.product_quantity_count.where(vendor_id: active_vendor_ids)
				active_products.each do |pro|
					vendor_currency = store.default_currency
					prrice = pro.price_values(store.default_currency, store)
					# prrice = pro.product_price(store.default_currency, store)
					on_sale = pro.on_sale? ? "Yes" : "No"
					base_image = pro&.images&.where(base_image: true)&.last
					addtional_images = Spree::Image.where(viewable: pro.variants_including_master, base_image: false)

					addtional_images_url = []
					if addtional_images
						addtional_images.each do |img|
							image_url = "https://" + store.url + "/"  + img.styles[3][:url]
							addtional_images_url.push image_url
						end
					end

					base_image_url = ""
					if base_image
						base_image_url = "https://" + store.url + "/" + base_image.styles[3][:url]
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
					puts pro.name
					puts pro.variants&.count
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
													prrice[:price], prrice[:final_price], vendor_currency.to_s, base_image_url, pro&.vendor&.name, addtional_images_url.join(', '),
													categories_name&.join(', '), on_sale, prrice[:sale_price].to_f.zero? ? "" : prrice[:sale_price] ,
													vendor_currency.to_s, "https://" + store.url  + "/" + pro.slug,
													color_and_size[:color], color_and_size[:size], color_and_size[:gender]]
							csv << data_arry
						end
					else
						data_arry = [pro.slug, pro.sku.to_s,"", pro&.name, desc, (pro.stock_status ? "in stock" : "out of stock"), "new",
												prrice[:price], prrice[:price], vendor_currency.to_s, base_image_url, pro&.vendor&.name, addtional_images_url.join(', '),
												categories_name.join(', '), on_sale, prrice[:sale_price].to_f.zero? ? "" : prrice[:sale_price] ,
												vendor_currency.to_s, "https://" + store.url  + "/" + pro.slug, "", "",""]
						csv << data_arry
					end


				end
			end

		end

		def self.bfs_product_report(store)
			headers = ["id","title", "description", "availability", "condition",
								"price", "image_link", "brand", "additional_image_link", "variations",
								"product_type","sale_price", "link"]
			CSV.open("public/bfs_products.csv", "wb") do |csv|
				csv << headers
				active_vendor_ids = store.client.vendors.active.select("id").pluck(:id)
				active_products = store.products.untrashed.approved.in_stock_status.product_quantity_count.where(vendor_id: active_vendor_ids)
				active_products.each do |pro|
					vendor_currency = store.default_currency
					prrice = pro.price_values(store.default_currency, store)
					on_sale = pro.on_sale? ? "Yes" : "No"
					base_image = pro&.images&.where(base_image: true)&.last
					addtional_images = Spree::Image.where(viewable: pro.variants_including_master, base_image: false)

					addtional_images_url = []
					if addtional_images
						addtional_images.each do |img|
							image_url = "https://" + store.url + "/"  + img.styles[3][:url]
							addtional_images_url.push image_url
						end
					end

					base_image_url = ""
					if base_image
						base_image_url = "https://" + store.url + "/" + base_image.styles[3][:url]
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
											types, on_sale,
											pro.on_sale[:sale_price].to_f.zero? ? "" : (prrice[:sale_price].to_s + vendor_currency.to_s) ,
											product_url]
					csv << data_arry
				end
			end

		end

		def create_data(store_name, preferences)
			store =  stores.new(name: store_name, code: store_name.parameterize, mail_from_address: store_name.parameterize + '@techsembly.com', default_url: store_name.parameterize + ".techsembly.com", url: store_name.parameterize + ".techsembly.com")
			store.save(validate: false)
			store.update_preferences(preferences) if preferences
			category = shipping_categories.create(name: store_name)
			shipping_methods.create!(name: store_name.parameterize, display_on: "both", shipping_category_ids: [category.id], calculator_type: "Spree::Calculator::Shipping::FlexiRate") if !store.fast_track?
			vendor = vendors.new(name: store_name, email: store_name.parameterize + self.id.to_s + "@gmail.com", master: true, agreed_to_client_terms: true)
			user = Spree.user_class.new(email: store_name.parameterize + self.id.to_s + "@gmail.com",password: '12345678@')
			user.spree_role_ids = Spree::Role.find_by(name: :vendor.to_s).id
			if user.valid?
				if vendor.valid?
					user.save
					vendor.save
					vendor.users << user
					vendor.save
				end
			end
			Spree::FastTrackStore.new().call(store) if store.fast_track?
		end

		def self.create_user_data(params, is_iframe_user=false, multi_vendor_store=false)
			user = Spree::User.new(password: params[:password], email: params[:email], is_iframe_user: is_iframe_user, state: is_iframe_user ? 'unverified' : 'createpayment')
			user.spree_roles = [Spree::Role.where(name: "client").first]
			if user.save
				client = Spree::Client.create(email: params[:email], multi_vendor_store: multi_vendor_store)
				user.client = client
				user.save
				user.generate_spree_api_key!
				return [user, client]
			else
				return [user, nil]
			end
		end

		def reporting_exchange_rate(to_currency)
			self.currencies.with_out_vendor_currencies.find_by(name: to_currency)
					.exchange_rates.find_by(name: self.reporting_currency).value rescue 1
		end

		def reporting_currency_exchange_rates
			self.currencies.with_out_vendor_currencies.map{
				|currency| currency.exchange_rates.where(name: self.reporting_currency).map{
					|rate| { to_currency: rate.name, from_currency: currency.name, value: rate.value }
				}.flatten
			}.flatten
		end

		def create_product
			product = products.new(store_ids: store_ids, name: stores&.last&.name, vendor_sku: "Dummy", product_type: "gift", status: "active", stock_status: true, count_on_hand: 100, minimum_order_quantity: 1, default_quantity: 1, pack_size: 1, price: "100.0", shipping_category_id: shipping_categories&.first&.id, available_on: DateTime.now, taxon_ids: [taxons&.last.id], selected_taxon_ids: [taxons&.last.id], vendor_id: vendors&.first&.id, send_gift_card_via: "email", ts_type: "monetary", digital_service_provider: "tsgifts", delivery_mode: "tsgift_digital", campaign_code: stores&.last&.name, voucher_email_image: "product_image", recipient_details_on_detail_page: true)
			product.classifications.last.store_id = store_ids.last
			product.save!
			product&.stock_items&.first.update_columns(count_on_hand: 100) if product.stock_items.present?
			stores&.last.redirects.create!(type_redirect: "relative", from: "/", to: "/#{product&.slug}")
		end

		private

		def ensure_base_currency
			self.master_vendor.assign_base_currency if self.master_vendor.present?
		end

		def set_default_exchange_rate(currency)
			currency = self.currencies.with_out_vendor_currencies.find_or_create_by(name: currency)

			self.supported_currencies.each do |to_currency|
				# Create exchange for newly added supported currency
				rate = currency.exchange_rates.find_or_initialize_by(name: to_currency)
				rate.value = (currency.name.eql?(to_currency) ? 1 : 0.0)
				rate.save

				# Create exchange for already existing supported currency to newly added supported currency
				existing_currency = self.currencies.with_out_vendor_currencies.find_by(name: to_currency)
				next if existing_currency.nil?

				existing_rate = existing_currency.exchange_rates.find_or_initialize_by(name: currency.name)
				existing_rate.value = (currency.name.eql?(existing_currency.name) ? 1 : 0.0)
				existing_rate.save
			end
		end

		def update_scheduled_reports_cron
			ScheduledReport.select{ |sr| sr.client_obj == self }.each do |report|
				report.send(:scheduled_report_cron_job) unless report.download_once?
			end
		end

		def create_tags
			client_email = self.email || self.users.last.email
			self.order_tags.create(label_name: 'Refunded', intimation_email: client_email)
			self.order_tags.create(label_name: 'Partially Refunded', intimation_email: client_email)
			self.order_tags.create(label_name: 'Test Order', intimation_email: client_email)
			self.order_tags.create(label_name: :'Quarantine'.to_s, intimation_email: client_email)
		end

		def assign_personas
			persona_types = ['default'.to_sym, :admin, :editor, :fulfilment]
			persona_types.each do |persona_type|
				new_persona = self.personas.create(persona_code: persona_type, name: persona_type.to_s.capitalize)
				mids = []

				if persona_type == :admin
					mids = MenuItem.where.not(url: ['/sub-client-landing', '/stock-product/:id']).permissible.ids
					new_persona.update(store_ids: self.stores.ids, menu_item_ids: mids.sort, campaign_ids: [])
				elsif persona_type == :editor
					product_menu_item_id = MenuItem.find_by(name: "Products", url: "#").id
					mids = MenuItem.where(url: ['/reporting', '/reports/including-ppi', '/reports/excluding-ppi', '/orders', '/products/approval', '/gift-cards-listing', '/gift-cards', "/settings/main", '/schedule-reports/:id', '/order-tags']).permissible.ids
					mids << product_menu_item_id
					new_persona.update(store_ids: self.stores.ids, menu_item_ids: mids.sort, campaign_ids: [])
				elsif persona_type == :fulfilment
					mids = MenuItem.where(url: ['/orders', '/gift-cards', "/active-physical-cards", '/givex-cards-list']).permissible.ids
					new_persona.update(store_ids: self.stores.ids, menu_item_ids: mids.sort, campaign_ids: [])
				end
			end
		end
  end
end

::Spree::Client.prepend Spree::ClientDecorator #if ::Spree::Client.included_modules.exclude?(Spree::ClientDecorator)
