## delete Data
models = ["FriendlyId::Slug", "ActsAsTaggableOn::Tag", "ActsAsTaggableOn::Tagging", "Doorkeeper::AccessGrant", "Doorkeeper::AccessToken", "Doorkeeper::Application", "Spree::Promotion::Rules::Store::HABTM_Stores", "Spree::Product::HABTM_Stores", "Spree::Store::HABTM_Products", "Spree::Store::HABTM_PromotionRules", "Spree::Wishlist", "ActiveStorage::Attachment", "ActiveStorage::Blob", "Spree::StoreCredit", "Spree::StorePaymentMethod", "Spree::StoreShippingMethod", "Spree::Review", "Spree::FeedbackReview", "Spree::WishedProduct", "Spree::Relation", "Spree::RelationType", "Spree::BraintreeCheckout", "Spree::GiftCard", "Spree::GiftCardTransaction", "Spree::Calculator", "Spree::PaymentMethod", "Spree::Promotion", "Spree::PromotionAction", "Spree::PromotionRule", "Spree::Payment", "Spree::Order", "Spree::User", "Spree::Role", "Spree::OptionType", "Spree::Product", "Spree::Variant", "Spree::Property", "Spree::ShippingMethod", "Spree::StockLocation", "Spree::ProductProperty", "Spree::LineItem", "Spree::Tracker", "Spree::Taxon", "Spree::Taxonomy", "Spree::Store", "Spree::Address", "Spree::Adjustment", "Spree::StoreCreditCategory", "Spree::Vendor", "Spree::CreditCard", "Spree::Asset", "Spree::Classification", "Spree::Country", "Spree::CustomerReturn", "Spree::InventoryUnit", "Spree::LegacyUser", "Spree::LogEntry", "Spree::OptionTypePrototype", "Spree::OptionValue", "Spree::OptionValueVariant", "Spree::OrderPromotion", "Spree::PaymentCaptureEvent", "Spree::Preference", "Spree::Price", "Spree::ProductOptionType", "Spree::ProductPromotionRule", "Spree::PromotionActionLineItem", "Spree::PromotionCategory", "Spree::PromotionRuleTaxon", "Spree::PromotionRuleUser", "Spree::PropertyPrototype", "Spree::Prototype", "Spree::PrototypeTaxon", "Spree::Refund", "Spree::RefundReason", "Spree::Reimbursement", "Spree::Reimbursement::Credit", "Spree::ReimbursementType", "Spree::ReturnAuthorization", "Spree::ReturnAuthorizationReason", "Spree::ReturnItem", "Spree::RoleUser", "Spree::Shipment", "Spree::ShippingRate", "Spree::ShippingCategory", "Spree::ShippingMethodCategory", "Spree::ShippingMethodZone", "Spree::State", "Spree::StateChange", "Spree::StockItem", "Spree::StockMovement", "Spree::StockTransfer", "Spree::StoreCreditEvent", "Spree::StoreCreditType", "Spree::TaxCategory", "Spree::TaxRate", "Spree::Zone", "Spree::ZoneMember", "Spree::VendorUser", "Spree::Answer", "Spree::Currency", "Spree::Customization", "Spree::CustomizationOption", "Spree::ExchangeRate", "Spree::LineItemCustomization", "Spree::LineItemExchangeRate", "Spree::Markup", "Spree::Notification", "Spree::NotificationsVendor", "Spree::Page", "Spree::Personalization", "Spree::Question", "Spree::ShippingCalculator", "Spree::Calculator::DefaultTax", "Spree::Calculator::FlatPercentItemTotal", "Spree::Calculator::FlatRate", "Spree::Calculator::FlexiRate", "Spree::Calculator::TieredPercent", "Spree::Calculator::TieredFlatRate", "Spree::Calculator::PercentOnLineItem", "Spree::Calculator::RelatedProductDiscount", "Spree::Calculator::GiftCardCalculator", "Spree::Calculator::PriceSack", "Spree::ReturnsCalculator", "Spree::Calculator::Shipping::FlatPercentItemTotal", "Spree::Calculator::Shipping::FlatRate", "Spree::Calculator::Shipping::FlexiRate", "Spree::Calculator::Shipping::PerItem", "Spree::Calculator::Shipping::PriceSack", "Spree::Calculator::Returns::DefaultRefundAmount", "Spree::Gateway", "Spree::PaymentMethod::Check", "Spree::PaymentMethod::StoreCredit", "Spree::PaymentMethod::Wallet", "Spree::PaymentMethod::GiftCard", "Spree::BillingIntegration", "Spree::Gateway::Bogus", "Spree::Gateway::AuthorizeNet", "Spree::Gateway::AuthorizeNetCim", "Spree::Gateway::BalancedGateway", "Spree::Gateway::Banwire", "Spree::Gateway::Beanstream", "Spree::Gateway::BraintreeGateway", "Spree::Gateway::CardSave", "Spree::Gateway::CyberSource", "Spree::Gateway::DataCash", "Spree::Gateway::Epay", "Spree::Gateway::Eway", "Spree::Gateway::EwayRapid", "Spree::Gateway::Maxipago", "Spree::Gateway::Migs", "Spree::Gateway::Moneris", "Spree::Gateway::PayJunction", "Spree::Gateway::PayPalGateway", "Spree::Gateway::PayflowPro", "Spree::Gateway::Paymill", "Spree::Gateway::PinGateway", "Spree::Gateway::Quickpay", "Spree::Gateway::SagePay", "Spree::Gateway::SecurePayAU", "Spree::Gateway::SpreedlyCoreGateway", "Spree::Gateway::StripeGateway", "Spree::Gateway::UsaEpayTransaction", "Spree::Gateway::Worldpay", "Spree::Gateway::BraintreeVzeroBase", "Spree::Gateway::BogusSimple", "Spree::Gateway::StripeElementsGateway", "Spree::Gateway::StripeApplePayGateway", "Spree::Gateway::BraintreeVzeroDropInUI", "Spree::Gateway::BraintreeVzeroPaypalExpress", "Spree::Gateway::BraintreeVzeroHostedFields", "Spree::Promotion::Actions::CreateAdjustment", "Spree::Promotion::Actions::CreateItemAdjustments", "Spree::Promotion::Actions::CreateLineItems", "Spree::Promotion::Actions::FreeShipping", "Spree::Promotion::Rules::Store", "Spree::Promotion::Rules::Country", "Spree::Promotion::Rules::FirstOrder", "Spree::Promotion::Rules::ItemTotal", "Spree::Promotion::Rules::OneUsePerUser", "Spree::Promotion::Rules::OptionValue", "Spree::Promotion::Rules::Product", "Spree::Promotion::Rules::Taxon", "Spree::Promotion::Rules::User", "Spree::Promotion::Rules::UserLoggedIn", "Spree::Image", "Spree::TaxonImage", "Spree::ReimbursementType::OriginalPayment", "Spree::ReimbursementType::Exchange", "Spree::ReimbursementType::Credit", "Spree::ReimbursementType::StoreCredit", "Spree::Tag", "Spree::Credit", "Spree::Debit"]
data_count = {}
models.each do |m|
	puts m
	data_count[m] = m.constantize.count
	puts m.constantize.count
end

Spree::Vendor.find_each.with_index do |v, index|
	v.landing_page_url =  v.name.parameterize + index.to_s
	v.save
end

# category hash with id for AR
sub = {}
Spree::Taxon.where(name: "Categories").first.children.each do |t1|
	sub[t1.name] = {}
	t1.children.each{|t2| sub[t1.name][t2.slug] = t2.id}
end

# assign page url to vendors if they are blank
Spree::Vendor.find_each do |v|
	if v.landing_page_url.blank?
		v.landing_page_url = v.name.parameterize
		v.save
	end
end


{"stores_id_eq":"2","status_in":"approved","taxons_permalink_eq":"categories/her/personalised-gifts"}
{"stores_id_eq":"2","status_in":"approved","taxons_id_or_taxons_slug_in":"59"}

def set_permalink
	if parent.present?
		self.permalink = [parent.permalink, (permalink.blank? ? name.to_url : permalink.split('/').last)].join('/')
	else
		self.permalink = name.to_url if permalink.blank?
	end
end

category = Spree::Taxon.find(1)
category.children.each do |c|
	c.set_permalink
	c.save
	c.children.each do |c1|
		c1.set_permalink
		c1.save
		c1.children.each do |c2|
			c2.set_permalink
			c2.save
		end
	end

end


# set base image as small and thumnail
images = Spree::Image.where(base_image: false).update_all(small_image: false)


# Clone shipping methods with shipping country is UK
vendors = Spree::Vendor.joins(:ship_address).where("spree_addresses.country_id = 77")
shipping_ids = [32,26]
shipping_methods = Spree::ShippingMethod.where(id: shipping_ids)

vendors.each do |v|
	next if v.id == 56
	shipping_methods.each do |sm|
		n_sm = v.shipping_methods.create(name: sm.name, display_on: sm.display_on,tracking_url: sm.tracking_url,admin_name: sm.admin_name,tax_category_id: sm.tax_category_id, code: sm.code, shipping_category_ids: sm.shipping_category_ids, zone_ids: sm.zone_ids,calculator_type: sm.calculator.type)
		n_sm.calculator.update_attribute(:preferences, sm.calculator.preferences)
	end
end



def self.download_images
	products = Spree::Product.where(id: [8144,8138])

	products.each do |p|
		p.images.each do |i|
			path = i.attachment.blob.service_url
			begin
				open(path) do |image|
					File.open("./gigky-bucket-images/#{i.id}.jpg", "wb") do |file|
						file.write(image.read)
					end
				end
			rescue OpenURI::HTTPError => ex
				puts "Handle missing video here"
			end
		end
	end
end

def self.upload_images
	target_folder_path = "./gigky-bucket-images"
	down_images = Dir.children(target_folder_path)
	test_arr = []
	down_images.each do |di|
		puts di
		path = target_folder_path + "/"+ di
		img = Spree::Image.find_by_id(di.split('.').first)
		next if img.blank?
		img.attachment.attach(io: File.open(path), filename: img.attachment_file_name)
		img.save
		test_arr.push di

		puts test_arr.to_s
	end
end

def extract_njal_products_with_zones_and_shipping
	headers = ["Name","Vendor Name","Shipping Zones","Product Stores","Product Shipping Category","Vendor Shipping Category", "Shipping Methods"]
	client = Spree::Client.where(name: "njal").last
	vendors = client.vendors
	CSV.open("public/products_csv.csv", "wb") do |csv|
		csv << headers
		vendors.each do |v|
			next if v.products.blank?
			shipping_zones = v&.shipping_methods&.map{|sm| sm.zones&.map(&:name)}&.flatten&.join(", ")
			shipping_categories = v&.shipping_methods&.map{|sm| sm.shipping_categories&.map(&:name)}&.flatten&.uniq&.join(", ")
			shipping_methods = v&.shipping_methods&.map(&:name)&.join(", ")
			v.products.each do |p|
				csv << [p.name, v&.name, shipping_zones, p&.stores&.map(&:name)&.join(", "), p&.shipping_category&.name, shipping_categories, shipping_methods]
			end
		end
		vendors.each do |v|
			next if v.products.present?
			shipping_zones = v&.shipping_methods&.map{|sm| sm.zones&.map(&:name)}&.flatten&.join(", ")
			shipping_categories = v&.shipping_methods&.map{|sm| sm.shipping_categories&.map(&:name)}&.flatten&.uniq&.join(", ")
			shipping_methods = v&.shipping_methods&.map(&:name)&.join(", ")
			csv << ["Vendor With Zero Products", v&.name, shipping_zones, "", "", shipping_categories, shipping_methods]
		end
	end
end


{address1: "49 South Second Freeway",address2: "Facere pariatur Nos",city: "Debitis id sint plac",country_id: "702",email: "juhu@mailinator.com",firstname: "Robert",phone: "+1 (599) 322-2558",zipcode: "72405"}

{"shipping_address"=>{"address1"=>"13 Green New Freeway", "address2"=>"Natus ad dolor modi ", "city"=>"Repellendus Aliqua", "country_id"=>"739", "zipcode"=>"54869"}, "billing_address"=>{"firstname"=>"Alice", "address1"=>"731 West Second Lane", "address2"=>"Quis libero illum c", "city"=>"Accusamus velit ea ", "country_id"=>"706", "zipcode"=>"60430", "phone"=>"+1 (564) 134-9061", "email"=>"tikyh@mailinator.net"}, "user"=>{"email"=>"fogi67@mailinator.com", "password"=>"[FILTERED]"}, "vendor"=>{"name"=>"Meredithhjhhjjh Moss", "contact_name"=>"Channing Rojas", "state"=>"pending", "page_enabled"=>"false", "phone"=>"+1 (226) 771-1187", "vacation_mode"=>"true", "vacation_start"=>"1997-10-18", "vacation_end"=>"2016-08-04", "conf_contact_name"=>"Chiquita Stuart", "landing_page_title"=>"Ad incididunt conseq", "enabled_google_analytics"=>"0", "google_analytics_account_number"=>"[FILTERED]", "description"=>"Sed rem occaecat dol", "additional_emails"=>"Commodo anim iusto l", "landing_page_url"=>"Cillum_jjjkjkmagni-ex-qui-hdjshjdsh", "designer_text"=>"Aut similique earum ", "banner_image_id"=>nil, "image_id"=>nil}, "access_token"=>"[FILTERED]"}


headers = ["Name","Vendor Name","Shipping Zones","Product Stores","Product Shipping Category","Vendor Shipping Category", "Shipping Methods"]
client = Spree::Client.where(name: "njal").last
vendors = client.vendors
CSV.open("public/products_csv.csv", "wb") do |csv|
	csv << headers
	vendors.each do |v|
		next if v.products.blank?
		shipping_zones = v&.shipping_methods&.map{|sm| sm.zones&.map(&:name)}&.flatten&.join(", ")
		shipping_categories = v&.shipping_methods&.map{|sm| sm.shipping_categories&.map(&:name)}&.flatten&.uniq&.join(", ")
		shipping_methods = v&.shipping_methods&.map(&:name)&.join(", ")
		v.products.each do |p|
			csv << [p.name, v&.name, shipping_zones, p&.stores&.map(&:name)&.join(", "), p&.shipping_category&.name, shipping_categories, shipping_methods]
		end
	end
	vendors.each do |v|
		next if v.products.present?
		shipping_zones = v&.shipping_methods&.map{|sm| sm.zones&.map(&:name)}&.flatten&.join(", ")
		shipping_categories = v&.shipping_methods&.map{|sm| sm.shipping_categories&.map(&:name)}&.flatten&.uniq&.join(", ")
		shipping_methods = v&.shipping_methods&.map(&:name)&.join(", ")
		csv << ["Vendor With Zero Products", v&.name, shipping_zones, "", "", shipping_categories, shipping_methods]
	end
end


headers = ["Product Name","Short Description","Long Description","Delivery Details","Image Count"]
client = Spree::Client.where(name: "njal").last
CSV.open("public/products_detail_csv.csv", "wb") do |csv|
	csv << headers
	client.products.each do |pro|
		if pro.long_description.blank? || pro.description.blank? || pro.delivery_details.blank? || (pro&.images&.count == 1)
			csv << [pro.name, pro.description.blank? ? "Blank" : "Present", pro.long_description.blank? ? "Blank" : "Present", pro.delivery_details.blank? ? "Blank" : "Present", pro&.images&.count&.to_s]
		end
	end
end

headers = ["Product Name"]
client = Spree::Client.where(name: "njal").last
CSV.open("public/products_without_variant_values.csv", "wb") do |csv|
	csv << headers
	client.products.each do |pro|
		if pro.variants.present?
			option_types_count = pro.option_types.ids
			without_values = pro.variants.select{|v| option_types_count.all? { |e| !v.option_values.map(&:option_type_id).include?(e) }}
			if without_values.present?
				csv << [pro.name]
			end
		end
	end
end

headers = ["Vendor Name","Stores", "Products Name"]
client = Spree::Client.where(name: "njal").last
vendors = client.vendors.active
CSV.open("public/active_vendors.csv", "wb") do |csv|
	csv << headers
	vendors.each do |v|
		products = v.products.untrashed.approved.in_stock_status.product_quantity_count
		stores = products.map{|p| p.stores.map(&:name)}.flatten.uniq.join(',')
		csv << [v.name, stores, products.map(&:name).join(',')]
	end
end


Spree::Vendor.find_each do |v|
	next if v.taxon.present?
	Spree::Taxonomy.create(name: v&.name&.parameterize, vendor_id: v&.id, client_id: v&.client_id)
end

Spree::Product.find_each do |pro|
	next if pro.vendor.blank?
	puts "zain"
	pro.taxon_ids << pro.vendor&.taxon&.id
	pro.save(validate: false)
end

# update international price for specific client's products

# get client by id
client = Spree::Client.find 1
# make sure mailchimp is synced
client.stores.each do |store|
  ::SpreeMailchimpEcommerce::UpdateStoreJob.perform_now(store.mailchimp_setting) if store.mailchimp_setting.present?
end
# here you go
client.products.each do |p|
  wide_price = p.exchanged(25, p.vendor.base_currency.try(:name), 'USD') if p.vendor&.base_currency.present?
  p.update(local_area_delivery: 0, wide_area_delivery: (wide_price || 0))
end
# update product currency prices
Searchkick.callbacks(:bulk) { Spree::Product.find_each { |p| ProductPricesWorker.perform_async(p.id) } }
# search elastic search stack for set of product ids
Spree::Product.search “*”, where: { id: product_ids_array }
# Genarate sitemaps
# RAILS_ENV=production bundle exec rake sitemap:refresh
rake sitemap:refresh

# migrate vendor from one to other client
old_vendor = Spree::Vendor.find(647)
vendor = Spree::Vendor.find(983)

Searchkick.callbacks(:bulk) do
  old_vendor.products.each do |p|
    prod_attrs = p.attributes.except("id", "shipping_category", "status", "count_on_hand", "stock_status", "store_ids", "created_at", "updated_at")

    new_p = vendor.products.new(prod_attrs.merge({client_id: vendor.client_id, price: p.price, trashbin: false}))
    new_p.save

    images = Spree::Image.where(id: p.images.ids)
    images.each do |img|
      dup_img = img.dup
      dup_img.viewable_id = new_p.master.id
      dup_img.attachment.attach(img.attachment.blob)
      dup_img.save
    end

    p.customizations.each do |cust|
      new_cust = new_p.customizations.new(label: cust.label, field_type: cust.field_type, price: cust.price, is_required: cust.is_required, order: cust.order, magento_id: cust.magento_id, store_ids: [], max_characters: cust.max_characters)
      new_cust.save

      cust.customization_options.each do |cust_opt|
        new_cust_opt = new_cust.customization_options.new(label: cust_opt.label, value: cust_opt.value, sku: cust_opt.sku, price: cust_opt.price, magento_id: cust_opt.magento_id, max_characters: cust_opt.max_characters, color_code: cust_opt.color_code)
        new_cust_opt.save
      end
    end
  end
end


# master veendor creation
Spree::Client.all.each do |c|
	if c&.master_vendor.blank?
		store_name = c&.stores&.first&.name || c.name
		store_name = store_name + c.id.to_s
		vendor = c.vendors.new(name: store_name, email: store_name.parameterize + "@gmail.com", master: true)
		user = Spree.user_class.new(email: store_name.parameterize + "@gmail.com",password: '12345678@')
		user.spree_role_ids = Spree::Role.find_by_name("vendor").id
		if user.valid?
			if vendor.valid?
				user.save
				vendor.save
				vendor.users << user
				vendor.save
			end
		end
	end
end


#convert gift type products to simple
pros = Spree::Product.where(product_type: 'gift')
pros.update_all(product_type: "simple")

#convert gift Card product to gift
pros = Spree::Product.where(is_gift_card: true)
pros.update_all(product_type: "gift")

#convert food items delivery types
pros = Spree::Product.where(product_type: 'food')
both_wali = pros.where(delivery_mode: "both")
both_wali.update_all(delivery_mode: "food_both")
delivery_wali = pros.where(delivery_mode: "delivery")
delivery_wali.update_all(delivery_mode: "food_delivery")
pickup_wali = pros.where(delivery_mode: "pick_up")
pickup_wali.update_all(delivery_mode: "food_pickup")

Spree::Role.create(name: "front_desk")

# gf = Spree::GiftCard.last(14)
gf.each do |g|
	SesEmailsDataWorker.perform_async(g.id, "voucher_confirmation_recipient")
end

orders = Spree::Order.complete.last(5)
orders.each do |g|
	SesEmailsDataWorker.perform_async(g.id, "order_confirmation_customer")
end

cards = Spree::TsGiftcard.last(3)
cards.each do |g|
	SesEmailsDataWorker.perform_async(g.id, "digital_ts_card_recipient")
end

client = Aws::SES::Client.new()
temp  = "voucher_confirmation_recipient_store_local_2"
resp = client.get_template({
															 template_name: temp
													 })


#When updating production dump to staging please do the following steps

# change users emails
# update product intimation and vendors emails, store emails(send emails as, receipent emails, bcc emails), vendor addtional emails
# delete mailchip setting, store ts , givex setting, payment meethods, lalamove, client ts setting
# production images

Spree::User.all.each{|u| u.update_column(:email, "a" + u.email)}
Spree::Product.update_all(intimation_emails: "")
Spree::Store.update_all(mail_from_address: "",recipient_emails: "",bcc_emails: "",ts_gift_card_email: "",ts_gift_card_password: "",ts_gift_card_url: "",finance_report_cc: "",finance_report_to: "",givex_url: "",givex_password: "",givex_user: "",lalamove_pk: "",lalamove_sk: "",lalamove_market: "",lalamove_pickup_order_tag_id: nil,lalamove_complete_order_tag_id: nil  )
Spree::Vendor.update_all(additional_emails: "")
MailchimpSetting.destory_all
Spree::Paymentmethod.destory_all
Spree::Client.update_all(ts_email: "",ts_password: "",ts_url: "")

#script for ST-944
aws_client = Aws::SES::Client.new()
templates = ["order_confirmation_vendor", "digital_ts_card_monetary_recipient", "digital_ts_card_experiences_recipient", "customer_password_reset", "monthly_sale_report", "order_tag_added", "order_tag_removed", "digital_givex_recipient", "order_confirmation_customer", "regular_shipment_customer", "voucher_confirmation_customer", "voucher_confirmation_recipient"]
Spree::Store.all.each do |store|
	store_templates = store&.email_templates
	templates.each do |temp|
		template_name = temp + "_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
		existing_templates = store_templates&.where(name: template_name)
		next if existing_templates&.count <= 1
		existing_templates.destroy_all
		begin
			aws_temp = aws_client.get_template(template_name: template_name)
			templated = true
		rescue => e
			templated = false if e.message.include?("Template #{template_name} does not exist")
		end
		store.email_templates.create(name: template_name, subject: aws_temp.template.subject_part, html: aws_temp.template.html_part, email_type: temp) if templated
	end
end

#script for creating email templates for iframe onboarding
templates_data =[
	{
		name: "iframe_otp_verification_" + ENV['SES_ENV'],
		subject: "OTP",
		html: "<p>This is your OTP {{otp}}</p>"
	},
	{
		name: "iframe_dns_details_" + ENV['SES_ENV'],
		subject: "DNS Details",
		html: "<p><b>DNS Details</b>\n<br> <b>cname:</b> {{cname}}</p>\n<br> <b>SSL CERTIFICATES:</b>\n<br><br> {{#each ssl_certificates}}\n <b>name:</b> {{name}}\n<br> <b>type:</b> {{type}}\n<br> <b>value:</b> {{value}}\n<br><br> {{/each}}"
	}
]
aws_client = Aws::SES::Client.new()
templates_data.each do |template|
	aws_template = {
        template: {
          template_name: template[:name],
          subject_part: template[:subject],
          html_part: template[:html]
        }
      }
	aws_client.create_template(aws_template)
end

#script to generate report data
Spree::SaleAnalysis.all.destroy_all
Spree::VendorSaleAnalysis.all.destroy_all
Spree::Order.all.each do |order|
	begin
		order.generate_sale_analysis
		order.generate_vendor_sale_analysis
	rescue => e
		Rails.logger.error(e.message)
		puts e.message
	end
end
# DEFAULT ORDER TAGS FOR CLIENT USED FOR REFUND
Spree::Client.find_each do |client|
	client.order_tags.find_or_create_by(label_name: "Refunded", intimation_email: client.email.to_s)
	client.order_tags.find_or_create_by(label_name: "Partially Refunded", intimation_email: client.email.to_s)
end

# rename refund reason for CSR
Spree::RefundReason.where(name: 'CSR LEAD REQUEST').update_all(name: 'As per supplied on CS Dashboard')

# check how many refunds without refund reason
rr = Spree::Refund.select do |refund|
    order = refund.order
    next if order.blank?
    next if order.store.blank?
    next if order.store.client.blank?
    client_refund_reasons = order.store.client.refund_reasons
    reason = client_refund_reasons.where(name: refund.notes.to_s.strip)
    reason.none?
end

# assign client refund reason to refunds if not already assigned
Spree::Refund.find_each do |refund|
    order = refund.order
    next if order.blank?
    next if order.store.blank?
    next if order.store.client.blank?
    client_refund_reasons = order.store.client.refund_reasons
    refund.reason ||= client_refund_reasons.find_or_create_by(name: refund.notes.to_s.strip)
    refund.save
end

# update stripe refunds meta
Spree::Refund.find_each do |refund|
  begin
    order = refund.order
    Stripe.api_key = order.store.stripegateway_payment_method.preferred_secret_key
    Stripe.stripe_account = order.store.send(:stripe_connected_account)

    refund_object = Stripe::Refund.retrieve(refund.transaction_id)
    puts refund_object.id if refund_object.present?
    meta = {}
    if refund_object.metadata.present?
      meta = refund_object.metadata
      puts "IF"
      refund_reson = order.refunds.map{|refund|refund.reason.try(:name)}.uniq.join(", ")
      if refund_reson.presence.present?
        meta["Refund Reason"] = refund_reson unless meta["Refund Reason"].present?
      end
      meta["Order Reference"] = "Techsembly Order ID: #{order.number}" unless meta["Order Reference"].present?
      puts "START"
      Stripe::Refund.update(refund_object.id, { metadata: meta.to_h })
      puts "Done"
    else
      puts "ELSE"
      refund_reson = order.refunds.map{|refund|refund.reason.try(:name)}.uniq.join(", ")
      meta = { "Order Reference" => "Techsembly Order ID: #{order.number}" }
      if refund_reson.presence.present?
        meta["Refund Reason"] = refund_reson unless meta["Refund Reason"].present?
      end
      puts "START"
      Stripe::Refund.update(refund_object.id, { metadata: meta.to_h })
      puts "Done"
    end
    rescue => e
      puts "CRASH"
      puts e.message
    end
end

#set test mode type
Spree::PaymentMethod.find_each do |payment_method|
	preferences = payment_method.preferences
	next unless preferences || preferences[:test_mode].blank?
	preferences[:test_mode] = [true, "true"].include?(preferences[:test_mode]) ? true : false
	payment_method.save
end

#script to geneate report data in spree_calculated_price table
Spree::Order.complete.find_each do |order|
  order.store_calculated_price_values
end

# ST-2086 (Daily stock items)
edit_stock = MenuItem.create([{
    name: 'Edit Stock Product',
    url: '/stock-product/:id',
    visible: false,
    img_url: 'assets/img/tag-new.svg',
    parent_id: nil,
    menu_permission_roles: ['client', 'sub_client', 'vendor'],
    namespace: true,
    priority: 5,
    permissible: false
}])

sub_client_users = Spree::User.joins(:spree_roles).where(:spree_roles => {:name => 'sub_client' }).uniq
sub_client_users.each(&:add_default_sub_client_routes)

#st-2086 sync product count on hand
Spree::Product.find_each(&:persist_count_on_hand)

##### Script to update calculated price values for line_items where order not exisit
line_item_ids_without_variant = []

line_item_ids_without_variant = Spree::LineItem.joins("LEFT JOIN spree_variants ON spree_variants.id = spree_line_items.variant_id").where("spree_variants.id is null").pluck("spree_line_items.id")

order_ids = Spree::LineItem.where(id: line_item_ids_without_variant).pluck(:order_id).uniq

Spree::Order.where(id: order_ids).find_each do |order|
  # manage order price _values
  if order.calculated_price.present?
    order.calculated_price.update(calculated_value: order.price_values)
  else
    begin
      order_meta_data = { promo_code: order.promo_code, payment_method: order.payments.completed.map { |k| k.payment_method.name }.join(', ') }
    rescue
      order_meta_data = { promo_code: order.promo_code, payment_method: "" }
    end
    Spree::CalculatedPrice.find_or_initialize_by(calculated_price: order, to_currency: order.currency, calculated_value: order.price_values, meta: order_meta_data).tap do |calculated_price|
      calculated_price.save! unless calculated_price.persisted?
    end
  end



  #manage line_items price_values
  order.line_items.find_each do |line_item|
    # update prices if line_item is present
    if line_item.calculated_price.present?
      line_item.calculated_price.update(calculated_value: line_item.price_values)
    else
      line_item_meta_data = { options_text: line_item&.variant&.options_text, shipping_method_name: line_item&.shipping_method_name,tag_list: line_item&.variant&.product&.tag_list&.first }
      Spree::CalculatedPrice.find_or_initialize_by(calculated_price: line_item, to_currency: line_item.currency, calculated_value: line_item.price_values, meta: line_item_meta_data).tap do |calculated_price|
        calculated_price.save! unless calculated_price.persisted?
      end
    end
  end
end
###########################
#Ticket ST-4089
#script to create product currency prices which are not calculated(fix min and max store price issuse)
Searchkick.callbacks(:bulk) { Spree::Product.select{|product| product.product_currency_prices.count == 0}.each { |p| p.send(:update_product_currency_prices) }}
######

# script to add ts campaigns ids into allow_campaign_ids column
data = [{"client-ts@test.com"=>[1, 2, 4]}] #this data will be from ts after fetching campaigns ids from client

data.each do |item|
  email = item.keys.first
  campaign_ids = item.values.first
  Spree::Client.all.find_each do |client|
		if client.ts_email == email
			users = client.users.joins(:spree_roles).where(:spree_roles => {:name => 'sub_client' })
			if users.present?
				users.each do |user|
					user.allow_campaign_ids = campaign_ids
					user.save!
				end
			end
		end
    end
end

# set store tyoe to noraml if it's empty
Spree::Store.find_each{ |store|
	if store.preferences[:store_type] == ''
		store.set_preference(:store_type, 'normal')
		store.save!
	end
}
# Ticket ST-4360 (Vendor agreement - Security Remediation)
Spree::Vendor.update_all(agreed_to_client_terms: true)


# Just Double check (ST-4486)

CSV.open("public/custom-price-integer-type.csv", "wb") do |csv|
    csv << ["Order number", "Line Item Id", "Custom Price", "Order State"]

    Spree::LineItem.where.not(custom_price: 0).each do |item|
        csv_line = []
        csv_line << item&.order&.number
        csv_line << item&.id
        csv_line << item&.custom_price.to_f
        csv_line << item&.order&.state
        csv << csv_line
    end
end

### Menu Item Permission Without Show And Index

MenuItem.find_by(name: 'Promotions', url: '/promotions/list-promotions').update(controller: "promotions",actions:[ "update", "create", "destroy"])
MenuItem.find_by(name: 'Gallery', url: '/gallery').update(controller: "galleries",actions:[ "update", "create", "destroy"])
MenuItem.find_by(name: 'Vendors', url: '/vendors').update(controller: "vendors",actions:[ "update", "create", "destroy","sign_up"])
MenuItem.find_by(name: 'Users', url: '/users').update(controller: "users",actions:[ "update", "create", "destroy","create_sub_client"])
MenuItem.find_by(name: 'Products', url: '#').update(controller: "products",actions:["update", "destroy", "trashbin", "destroy_multiple"])
MenuItem.find_by(name: 'Create Product', url: "/create-product").update(controller: nil,actions:[ "create"])
MenuItem.find_by(name: 'Product Approval', url: "/products/approval").update(controller: nil,actions:[])
MenuItem.find_by(name: 'Product Stocks', url: "/inventory/product-stocks").update(controller: nil,actions:["update_stock"])
MenuItem.find_by(name: 'Preview Product', url: "/product/:id/preview").update(controller: nil,actions:[])
MenuItem.find_by(name: 'Product Trashbin', url: "/product-trashbin").update(controller: "nil",actions:[ "destroy"])
MenuItem.find_by(name: 'Import Stocks', url: "/inventory/import-stocks").update(controller: "nil",actions:[ "import_stocks"])
MenuItem.find_by(name: 'Stores', url: '/stores').update(controller: "stores",actions:["update", "destroy"])
MenuItem.find_by(name: 'Conversations', url: '/questions/all-questions').update(controller: "questions",actions:["update", "create", "destroy","reply"])
MenuItem.find_by(name: 'GiveX Cards', url: '/givex-cards-list').update(controller: "givex_cards", actions: ['create', 'pdf_details', 'givex_request', 'givex_activate_card', 'cancel_gift_cards'])

### Menu Item Permission With Show And Index

MenuItem.find_by(name: 'Promotions', url: '/promotions/list-promotions').update(controller: "promotions",actions:["index", "update", "show", "create", "destroy"])
MenuItem.find_by(name: 'Gallery', url: '/gallery').update(controller: "galleries",actions:["index", "update", "show", "create", "destroy"])
MenuItem.find_by(name: 'Vendors', url: '/vendors').update(controller: "vendors",actions:["index", "update", "show", "create", "destroy","sign_up"])
MenuItem.find_by(name: 'Users', url: '/users').update(controller: "users",actions:["index", "update", "show", "create", "destroy","create_sub_client"])
MenuItem.find_by(name: 'Products', url: '#').update(controller: "products",actions:["update", "show", "destroy", "trashbin", "destroy_multiple"])
MenuItem.find_by(name: 'Create Product', url: "/create-product").update(controller: nil,actions:[ "create"])
MenuItem.find_by(name: 'Product Approval', url: "/products/approval").update(controller: nil,actions:[ "index"])
MenuItem.find_by(name: 'Product Stocks', url: "/inventory/product-stocks").update(controller: nil,actions:[ "index","update_stock"])
MenuItem.find_by(name: 'Preview Product', url: "/product/:id/preview").update(controller: nil,actions:[ "show"])
MenuItem.find_by(name: 'Product Trashbin', url: "/product-trashbin").update(controller: "nil",actions:[ "destroy"])
MenuItem.find_by(name: 'Import Stocks', url: "/inventory/import-stocks").update(controller: "nil",actions:[ "import_stocks"])


MenuItem.find_by_name("Stores").update(controller: "stores",actions:["index","show", "update", "destroy"])
MenuItem.find_by_name("Conversations").update(controller: "questions",actions:["index","show", "update", "create", "destroy","reply"])
MenuItem.find_by(name: 'GiveX Cards', url: '/givex-cards-list').update(controller: "givex_cards", actions: ['index', 'create', 'show', 'pdf_details', 'givex_request', 'givex_activate_card', 'cancel_gift_cards'])

# ST-4647 Cache clear for Image size and conversion
product_cache_keys = Spree::Store.all.map { |s| s.products.pluck(:slug).map { |slug| "#{slug}-store-#{s.id}" } }
Rails.cache.redis.keys.each do |cache|
	Rails.cache.delete(cache) if product_cache_keys.flatten.any? { |key| cache.include?(key) }
end
webp_images = Spree::Image.joins(:attachment_blob).where('active_storage_blobs.content_type = ? AND spree_assets.created_at < ?', 'image/webp', Date.today)
webp_images.each do |img|
	begin
		next unless img.attachment_blob.content_type.include?("webp")
		viewable_name = img.viewable_type
		dup_image = img.dup
		dup_image.attachment.attach(img.attachment.blob)
		# dup_image.attachment.blob.key = nil
		dup_image.viewable_type = nil
		img.destroy
		dup_image.save!
		dup_image.update_column(:viewable_type, viewable_name)
	rescue
		Rails.logger.info("webp images issue ----- #{img.id}");
	end
end

# st-5372
# Spree::Store.select{ |s| s.preferences[:start_date].present? }.count
# count = 0
# Spree::Store.select{ |s| s.preferences[:start_date].present? }.each do |store|
# 	begin
# 			store.preferences[:start_date] = store.preferences[:start_date].to_datetime.beginning_of_day
# 			store.preferences[:end_date] = store.preferences[:end_date].to_datetime.end_of_day
# 			store.preferences[:zone] = "UTC"

# 			puts store.id
# 			count = count + 1 if store.save
# 	rescue => e
# 			puts e.message
# 	end
# end
# st-5372

# Cancel gift card from CS dashboard | ST-3393
ts_client = PG.connect host: 'TS-DB-HOST', port: 5432, dbname: 'TS-DB', user: 'TS-DB-USER', password: 'TS-DB-PASSWORD'
ts_client_ids = [201, 1, 199, 225] # need to replace with actual client ids
# cards_data = ts_client.exec("SELECT DISTINCT gift_cards.id, gift_cards.number, gift_cards.status, transactions.store_id, transactions.created_at FROM gift_cards INNER JOIN transactions ON gift_cards.id = transactions.gift_card_id ORDER BY transactions.created_at ASC")
cards_data = ts_client.exec("SELECT DISTINCT gift_cards.id, gift_cards.number, gift_cards.status, transactions.store_id, transactions.created_at FROM gift_cards INNER JOIN transactions ON gift_cards.id = transactions.gift_card_id WHERE gift_cards.status <> '0' AND gift_cards.client_id IN (#{ts_client_ids.join(',')}) ORDER BY transactions.created_at ASC")
count = 0

Spree::TsGiftcard.all.each do |ts_card|
	card_hash = cards_data.select { |c| c['number'] == ts_card.number }[0]
	next unless card_hash.present?
	begin
		arr = {'0' => 'initiated', '1' => 'active', '2' => 'blocked', '3' => 'canceled', '4' => 'lost'}
		response_was = JSON.parse(ts_card.response)
		response_was_value = response_was['value']
		response_was_value['initial_store_id'] = card_hash['store_id']
		response_was_value['status'] = arr[card_hash['status']]
		response_was['value'] = response_was_value
		ts_card.response = response_was.to_json
		ts_card.status = arr[card_hash['status']]
		count = count + 1 if (ts_card.save rescue false)
	rescue => e
		puts e.message
	end
end

# Spree::TsGiftcard.find_each do |card|
# 	next if card.response.nil?
# 	res = JSON.parse(card.response)
# 	status = res['value']['status']
# 	card.update_column(:status, status)
# end



# Script to Create Single Sign on admin and two new roles.

admin_role = Spree::Role.create(name: "service_login_admin")
sub_admin_role = Spree::Role.create(name: "service_login_sub_admin")
sso_admin_user = Spree::ServiceLoginUser.new(name: "admin", email: "service_login_admin@sabre.com", password: "123123!")
sso_admin_user.spree_roles << admin_role
sso_admin_user.save!

# ST-5169
givex_cards_menu = ::MenuItem.find_by(name: "GiveX Cards", url: "/givex-cards-list")
givex_cards_menu.controller = 'givex_cards'
givex_cards_menu.actions = ['index', 'create', 'show', 'pdf_details', 'givex_request', 'givex_activate_card', 'cancel_gift_cards']
givex_cards_menu.save

#ST-5520 Assign option values text to line items
Spree::LineItem.find_each do | item|
  option_values_text = []
  item.variant&.option_values&.each do |option_value|
    option_values_text.push({value: "#{option_value.option_type&.name} : #{option_value.presentation}"})
  end
  item.update_columns option_values_text: option_values_text
end

# ST-5737
settings_parent_menu = MenuItem.find_by(name: 'Settings', url: '/settings/main')
MenuItem.create([
	{name: 'AWS Files', url: '/aws/list-aws-file', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 54, permissible: true}
])

aws_files_menu = MenuItem.find_by(name: 'AWS Files', url: '/aws/list-aws-file')
if aws_files_menu.present?
    MenuItem.create([
        {name: 'Create AWS Files', url: '/aws/create-aws-file', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: aws_files_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 54.1, permissible: false}
    ])
end
# ST-5289 Bulk user update
Spree::Client.all.find_each do |client|
	client.send(:assign_personas)
end
# ST-5623 Extra TS cards generated for multiple clients
Spree::TsGiftcard.find_each do |giftcard|
	ref_num = "TS#{giftcard.id}#{SecureRandom.random_number(10 ** 4)}"
	giftcard.update_column(:reference_number, ref_num)
end
#ST-5787 Serial Number to report and reporting dashboard
Spree::FulfilmentInfo.find_each { |info|
  replacement_info = info.replacement_info || {}
  info.update_column(:state, :fulfiled) if info.original? && info.shipment.fulfilment_status == 'fulfiled'
  info.update_column(:state, :fulfiled) if info.replacement? && replacement_info["state"] == 'fulfiled'
  puts 'ok'
}

# Ticket = US1946476
users_menu = MenuItem.find_by(name: 'Users', url: '/users')
users_menu.actions.push('create_fd_user')
users_menu.save

stores_menu = MenuItem.find_by(name: 'Stores', url: '/stores')
MenuItem.where(name: 'Create Route', url: '/create-route').update_all(parent_id: stores_menu.id)
MenuItem.where(name: 'Edit Route', url: '/edit-route/:id').update_all(parent_id: stores_menu.id)

stores_menu = MenuItem.find_by(name: 'Stores', url: '/stores')
create_route = MenuItem.find_by(url: '/create-route')
edit_route = MenuItem.find_by(url: '/edit-route/:id')

Spree::User.joins(:spree_roles).where(spree_roles: { name: 'sub_client' }).each do |sub_user|
	sub_user.menu_item_users.where(menu_item_id: [create_route.id, edit_route.id]).destroy_all

	store_permission = sub_user.menu_item_users.find_by(menu_item_id: stores_menu.id)
	if store_permission.present?
		sub_user.menu_item_users.create(menu_item_id: create_route.id, parent_id: store_permission.id, visible: create_route.visible, permissible: create_route.permissible)
		sub_user.menu_item_users.create(menu_item_id: edit_route.id, parent_id: store_permission.id, visible: edit_route.visible, permissible: edit_route.permissible)
	end
end

#US1943929 added refund state
Spree::Refund.update_all state: :succeeded

#US1956774 updating store language which doesn't exist now
allowed_languages = ["ar", "zh-Hans", "zh-Hant", "en", "fr", "de", "it", "ja", "cnr", "pt", "es", "th"]
Spree::Store.all.each do |store|
  default_language = store.preferences[:default_language]
  unless allowed_languages.include?(default_language)
    store.update_preferences(default_language: "en")
  end         
end

# ticket = US1966653 (DKIM)
Spree::EmailTemplate.create({
	name: "dkim_instructions_#{ENV['SES_ENV']}",
	email_type: "dkim_instructions_#{ENV['SES_ENV']}",
	html: "HTML inprogress",
	subject: "Important: DKIM Setup Instructions for {{domain}}"
})
Spree::User.joins(:spree_roles).where(spree_roles: {name: 'sub_client'}).each do |sub_user|
	if sub_user.menu_items.include?(whitelisted_emails)
		sub_user.menu_items << whitelisted_new_domain unless sub_user.menu_items.include?(whitelisted_new_domain)
		sub_user.menu_items << whitelisted_show_domain unless sub_user.menu_items.include?(whitelisted_show_domain)
		sub_user.save(validate: false)
	end
end
# Defect = DE303584, ticket = US1966653 (DKIM)
whitelisted_emails = MenuItem.find_by(name: 'Invite for Whitelisting', url: '/whitelist-email/list-whitelist-email')
MenuItem.create([
	{name: 'Whitelist New Domain', url: '/whitelist-email/create-whitelist-domain', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: whitelisted_emails.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.24", permissible: false},
	{name: 'Whitelist Show Domain', url: '/whitelist-email/show-whitelist-domain/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: whitelisted_emails.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.25", permissible: false}
])

Spree::EmailTemplate.create({
	name: "dkim_success_#{ENV['SES_ENV']}",
	email_type: "dkim_success_#{ENV['SES_ENV']}",
	html: "HTML inprogress",
	subject: "Confirmation: Domain Whitelisting and DKIM Setup Successful for {{domain}}"
})
#US1964351 updating priority after changing parent of 'Create Gift Cards'
update_menu_item_name = MenuItem.find_by(name: 'Create Gift Cards', url: '/create-gift-cards')
update_menu_item_name.update(name: 'Create Gift Card')
menu_item_update = { 
  'Create Gift Card' => '5', 
  'TS Campaigns' => '5.02', 
  'TS Stores' => '5.03', 
  'TS Front Desk Users' => '5.04', 
  'Transaction Reason' => '5.05', 
  'Client Setting' => '5.06' 
}
MenuItem.transaction do
  menu_item_update.each do |name, priority|
    menu_item = MenuItem.find_by(name: name)
    if menu_item.present?
      menu_item.update(priority: priority)
      menu_item.update(permissible: true) if name == 'Create Gift Card'
			ts_gift_curate = MenuItem.find_by(name: 'TS Gifts Curate', url: '/gift-cards')
			menu_item.update(parent_id: ts_gift_curate.id) if name == 'Create Gift Card'
    end
  end
end
menu_item = MenuItem.find_by(name: 'Create Gift Card', url: '/create-gift-cards')
if menu_item
  admin_personas = Spree::Persona.where(persona_code: "admin")
  admin_personas.each do |persona|
    unless persona.menu_item_ids.include?(menu_item.id.to_s)
      persona.menu_item_ids << menu_item.id.to_s
      persona.save
    end
  end 
end

# US1966530
# Create a new email template for vendor invitation
Spree::EmailTemplate.create({
  name: "spree_vendor_invite_#{ENV['SES_ENV']}",
  email_type: "spree_vendor_invite_#{ENV['SES_ENV']}",
  html: "<!DOCTYPE html> <html> <head> <meta http-equiv='Content-Type' content='text/html; charset=utf-8' /> </head> <body> <h4> Welcome to {{store_name}} </h4> <p> {{name}} has invited you to access {{store_name}} as a vendor. To accept this invitation, create a vendor account. </p> <p> If you weren't accepting this invitation, you can ignore </p> <p> This invitation will expire in 7 days. </p> <p> <a href={{link}}>Create Vendor Account</a> </p> </body> </html>",
  subject: "You have a new message",
})

# ST-5893
Spree::TsGiftcard.is_generated.update_all request_state: :processed
Spree::GivexCard.is_generated.update_all request_state: :processed

#US1971878 Restrict Store Creation to Selected Sub-Users
parent_store = MenuItem.find_by(name: 'Stores', url: '/stores')
parent_store.update_column(:actions, (parent_store.actions - ['create']))
menu_item = MenuItem.find_by(name: 'Create Store', url: '/create-store')
if menu_item
	menu_item.update(permissible: true, actions: ['create'])
  admin_personas = Spree::Persona.where(persona_code: "admin")
  admin_personas.each do |persona|
    unless persona.menu_item_ids.include?(menu_item.id.to_s)
      persona.menu_item_ids << menu_item.id.to_s
      persona.save
    end
  end 
end

# ticket = US1966656
Spree::EmailTemplate.create({
		name: "send_ssl_verification_#{ENV['SES_ENV']}",
		email_type: "send_ssl_verification_#{ENV['SES_ENV']}",
		html: "HTML in progress...!",
		subject: "Important: SSL Request for for {{domain}}"
})
# US1981845 = Assign Quarantine tags to existing clients
clients = Spree::Client.all
clients.find_each do |client|
	client_email = client.email || client.users.with_role('client').email rescue nil
	client.order_tags.find_by(label_name: :'Quarantine'.to_s) || client.order_tags.create(label_name: :'Quarantine'.to_s, intimation_email: client_email)
end
