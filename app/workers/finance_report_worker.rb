class FinanceReportWorker
  require 'concerns/archive'
  include Sidekiq::Worker

  sidekiq_options queue: 'finance_feed'

  def finance_report(store, report, q)
    header = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Time Placed", "Order Status", "Customer Full Name", "Customer Address", "Customer First Name",
      "Customer Last Name", "Shipping Delivery Country", "Customer Phone", "Customer Email",
      "Product name","Product Sku", "Vendor Sku", "Variant", "Product quantity", "Product price", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time",
      "Order currency","Vendor Currency", "Exchange Rate", "Sub Total", "Tax(inclusive)", "Tax(exclusive)",
      "Shipping amount", "Total Shipping amount", "Discount amount", "Associated Order Value" ,"Promo Code",
      "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Iso Number",
      "Special Message","Card Type", "Recipient Name", "Recipients First Name", "Recipients Last Name", "Recipient Email", "Recipient Phone Number",  "Marketing Enabled", "Product Tag"]

		file_name = "#{DateTime.now.strftime('%d-%b-%Y')}-#{DateTime.now.strftime('%I:%M%p')}-#{store.name.parameterize}-finance-report"
		file_path = "public/reports/#{file_name}"

    is_show_gift_card_column = store&.client&.show_gift_card_number
    header.insert(header.find_index("Gift Card Iso Number"),"Gift Card Number") if is_show_gift_card_column
		csv_file_path = "#{file_path}.csv"
		CSV.open(csv_file_path, "wb") do |csv|
			orders = store.orders.complete.includes(:user, :promotions, :payments, :shipments, :bill_address, :ship_address, :order_tags, :givex_cards, line_items: [:variant, :line_item_customizations, :line_item_exchange_rate, vendor: [:users]] )
						.ransack(q).result(distinct: true).order("completed_at DESC")
			csv << header
			orders.each do |order|
        customer_address = order.bill_address
        ship_address = order.ship_address
        customer_name = customer_address&.full_username
        promo_code = order.promotions&.map(&:code).join(",")
        payment_method = order.payments.completed.map {|k| k.payment_method.name}.join(', ')
        shipment_state = order.shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
				enabled_marketing = (order.enabled_marketing ? 'Yes' : 'No')
        order_attrs = order.price_values(order.currency)
        @line_items = order_attrs[:line_items]
        @shipments = order_attrs[:shipments]
        order.price_values(order.currency)
        @line_items.each do |line_item|
          item_shipmnent = @shipments.find_by_line_item_id(line_item.id)
          csv_line = []
          line_item.price_values(order.currency)
          voucher_recipent_name = line_item&.line_item_customizations&.where(name: 'Gift Card Name')&.first&.try(:value)
          csv_line << order.number
          csv_line << order&.store&.name
          csv_line << line_item&.product&.vendor&.name
          csv_line << "UTC"
          csv_line << store.local_date(order.completed_at).strftime("%B %d, %Y")
          csv_line << store.local_date(order.completed_at).strftime("%I:%M %p")
          csv_line << order.state
          csv_line << customer_name
          csv_line << customer_address&.get_full_address
          csv_line << customer_address&.firstname
          csv_line << customer_address&.lastname
          csv_line << ship_address&.country&.name
          csv_line << customer_address&.phone
          csv_line << order.email
          csv_line << line_item&.variant&.name
          csv_line << line_item&.variant&.sku
          csv_line << line_item.product.vendor_sku
          csv_line << line_item&.options_text
          csv_line << line_item&.quantity
          csv_line << line_item.exchanged_prices[:sub_total]
          csv_line << item_shipmnent&.delivery_pickup_date&.strftime("%B %d, %Y")
          csv_line << item_shipmnent&.delivery_pickup_time
          csv_line << store.local_date(item_shipmnent&.shipped_at)&.strftime("%B %d, %Y")
          csv_line << store.local_date(item_shipmnent&.shipped_at)&.strftime("%I:%M %p")
          csv_line << line_item.line_item_exchange_rate&.to_currency
          csv_line << line_item.line_item_exchange_rate&.from_currency
          csv_line << line_item.line_item_exchange_rate&.exchange_rate
          csv_line << line_item.exchanged_prices[:amount]
          csv_line << "%.2f" % line_item.total_tax(:included)
          csv_line << "%.2f" % line_item.total_tax(:additional)
          csv_line << "%.2f" % (order.exchanged_prices[:vendor_based_shipment][line_item.vendor_id].to_f)
          csv_line << order.exchanged_prices[:ship_total]
          csv_line << order.exchanged_prices[:promo_total]
          csv_line << order.exchanged_prices[:total]
          csv_line << promo_code
          csv_line << payment_method
          csv_line << line_item.shipping_method_name
          csv_line << shipment_state
          csv_line << order&.order_tags&.pluck('label_name')&.join(',')
          csv_line << "#{line_item.gift_card_number}" if is_show_gift_card_column
          csv_line << "#{line_item.gift_card_iso_number}"
          csv_line << line_item.message
          csv_line << line_item.delivery_mode
          csv_line << (line_item.is_gift_card? ? voucher_recipent_name : "#{line_item.receipient_first_name} #{line_item.receipient_last_name}")
          csv_line << (line_item.is_gift_card? ? voucher_recipent_name : line_item.receipient_first_name)
          csv_line << (line_item.is_gift_card? ? voucher_recipent_name : line_item.receipient_last_name)
          csv_line << (line_item.is_gift_card? ? line_item&.line_item_customizations&.where(name: 'Gift Card Email')&.first&.try(:value) : line_item.receipient_email)
					csv_line << line_item&.receipient_phone_number
          csv_line << enabled_marketing
					csv_line << line_item&.product&.tag_list&.first
          csv << csv_line
        end
			end
		end
		store.add_to_zip(file_path, (store.sales_report_password || ENV['ZIP_ENCRYPTION']))
		report.save_csv_file("#{file_path}.zip", "#{file_name}.zip")
		File.delete(csv_file_path) if File.exist?(csv_file_path)
	end

	def perform(store_id)
		store = Spree::Store.find(store_id)
		report = store.reports.create(feed_type: "finance_report")
		start_datetime = store.orders_fetch_from_type(store.get_preference(:orders_fetch_from)) == :beginning_of_month ? Time.zone.now.beginning_of_month : store.finance_report_generated_at
		q = { completed_at_gt_time_scope: start_datetime.to_s }
		finance_report(store, report, q)
		store.update_column(:finance_report_generated_at, Time.zone.now)
		SesEmailsDataWorker.perform_async(store_id, "monthly_sale_report",report.id)
	end

end
