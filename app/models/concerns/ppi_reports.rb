module PpiReports
  attr_accessor :file_path, :password
  class << self
    def to_csv(user, q = {})
      ppi_included=q[:show_ppi]
      vendor_dashboard_headers = ["Order number", "Storefront", "Timezone", "Date Placed", "Status", "Customer", "Currency", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Tax(inclusive)", "Tax(exclusive)", "Tags", "Total"]
      ppi_headers = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Order Status", "Customer Full Name", "Customer Address", "Customer First Name",  "Customer Last Name", "Shipping Delivery Country", "Customer Phone", "Customer Email", "Product name", "Brand Name", "Product Sku", "Vendor Sku","Barcode Number", "Variant", "Product quantity", "Product price","Unit Cost Price" ,"Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Order currency", "Vendor Currency", "Exchange Rate", "Sub Total","Report Currency sub Total", "Report Currency Code", "Report Currency Exchange Rate", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount Amount", "Order Subtotal", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags","Gift Card Number", "Gift Card Iso Number", "Special Message", "Card Type", "Recipient Name", "Recipients First Name", "Recipients Last Name" ,"Recipient Email", "Recipient Phone Number", "Marketing Enabled", "Product Tag", "Reference Number", "Notes / Comments"]
      non_ppi_headers=["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Order Status", "Product name", "Brand Name", "Product Sku", "Vendor Sku", "Barcode Number" ,"Variant", "Product quantity", "Product price","Unit Cost Price" ,"Order currency", "Vendor Currency", "Exchange Rate", "Sub Total","Report Currency sub Total", "Report Currency Code", "Report Currency Exchange Rate", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount Amount","Order Subtotal", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Number", "Gift Card Iso Number", "Card Type", "Marketing Enabled", "Product Tag", "Reference Number", "Notes / Comments"]
      headers = (ppi_included=="true") ? ppi_headers : non_ppi_headers
      is_show_gift_card_column = user&.client&.show_gift_card_number
      rates=user&.client&.reporting_currency_exchange_rates
      # headers.insert(headers.find_index("Gift Card Iso Number"),"Gift Card Number") if is_show_gift_card_column
      CSV.open("#{@file_path}.csv", "wb") do |csv|
        q[:shipments_vendor_id_in] = user&.client&.vendor_ids
        q = Spree::Order.complete.includes(:shipments, :line_items => [:sale_analysis, :givex_cards, :ts_giftcards]).ransack(q)
        orders = q.result(distinct: true).order("completed_at DESC")
        csv << headers
        orders.each do |order|
          shipments = order.shipments
          shipment_state = shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
          sale_analysis_discount = "%.2f" % 0
          order_subtotal = "%.2f" % 0
          order.line_items.each_with_index do |line_item, index|
            item_shipmnent = shipments&.find_by('spree_shipments.line_item_id = ?', line_item&.id)
            exchange_value = line_item&.saved_exchange_rate || 1
            shipping_amount = (item_shipmnent&.cost.to_f * exchange_value)
            sale_analysis = line_item.sale_analysis
            if index.zero?
              sale_analysis_discount = "%.2f" % sale_analysis&.discount_amount.to_f
              order_subtotal = "%.2f" % sale_analysis&.order_subtotal.to_f
            end

            column_value = {
              'Order number' => sale_analysis&.order_number,
              'Storefront' => sale_analysis&.storefront,
              'Vendor' => sale_analysis&.vendor,
              'Vendor Timezone' => user&.client&.timezone,
              'Date Placed' => sale_analysis&.date_placed&.strftime("%B %d, %Y"),
              'Order Status' => sale_analysis&.order_status,
              'Customer Full Name' => sale_analysis&.customer_full_name,
              'Customer Address' => sale_analysis&.customer_address,
              'Customer First Name' => sale_analysis&.customer_first_name,
              'Customer Last Name' => sale_analysis&.customer_last_name,
              'Shipping Delivery Country' => sale_analysis&.shipping_delivery_country,
              'Customer Phone' => sale_analysis&.customer_phone,
              'Customer Email' => sale_analysis&.customer_email,
              'Product name' => sale_analysis&.product_name,
              'Brand Name' => sale_analysis&.brand_name,
              'Product Sku' => sale_analysis&.product_sku,
              'Vendor Sku' => sale_analysis&.vendor_sku,
              'Barcode Number' => sale_analysis&.barcode_number,
              'Variant' => sale_analysis&.variant,
              'Product quantity' => sale_analysis&.product_quantity,
              'Product price' => sale_analysis&.product_price,
              'Unit Cost Price' => "%.2f" % sale_analysis&.unit_cost_price.to_f,
              'Delivery/Pick-up Date' => sale_analysis&.delivery_pickup_date&.strftime("%B %d, %Y"),
              'Delivery/Pick-up Time' => sale_analysis&.delivery_pickup_time,
              'Shipped Date' => local_date(item_shipmnent&.shipped_at, user&.client&.timezone)&.strftime("%B %d, %Y"),
              'Shipped Time' => local_date(item_shipmnent&.shipped_at, user&.client&.timezone)&.strftime("%I:%M %p"),
              'Order currency' => sale_analysis&.order_currency,
              'Vendor Currency' => sale_analysis&.vendor_currency,
              'Exchange Rate' => sale_analysis&.exchange_rate,
              'Sub Total' => sale_analysis&.sub_total,
              'Report Currency sub Total' => "%.2f" % ((sale_analysis&.sub_total.to_f)*(user&.client.reporting_exchange_rate(order.currency))),
              'Report Currency Code' => user&.client&.reporting_currency,
              'Report Currency Exchange Rate' => user&.client.reporting_exchange_rate(order.currency),
              'Tax(inclusive)' => sale_analysis&.tax_inclusive,
              'Tax(exclusive)' => sale_analysis&.additional_tax,
              'Shipping amount' => ("%.2f" % sale_analysis&.shipping_amount.to_f),
              'Total Shipping amount' => (index.zero? ? sale_analysis&.total_shipping_amount : "%.2f" % 0),
              'Discount Amount' => 0,
              'Order Subtotal' => "",
              'Associated Order Value' => sale_analysis&.associated_order_value,
              'Promo Code' => "",
              'Order payment method' => sale_analysis&.payment_method,
              'Shipping Method' => sale_analysis&.shipping_method,
              'Order shipped' => shipment_state,
              'Tags' => order&.order_tags&.pluck('label_name')&.join(','),
              'Gift Card Number' => line_item&.gift_card_number,
              'Gift Card Iso Number' => line_item&.gift_card_iso_number,
              'Special Message' => sale_analysis&.special_message,
              'Card Type' => "#{sale_analysis&.product_card_type_with_ts_type}",
              'Recipient Name' => sale_analysis&.recipient_name,
              'Recipients First Name' => sale_analysis&.recipient_first_name,
              'Recipients Last Name' => sale_analysis&.recipient_last_name,
              'Recipient Email' => sale_analysis&.recipient_email,
              'Recipient Phone Number' => sale_analysis&.recipient_phone_number,
              'Marketing Enabled' => sale_analysis&.marketing_enabled,
              'Product Tag' => sale_analysis&.product_tag,
              'Reference Number' => order.spo_invoice,
              'Notes / Comments' => order&.notes
            }
            values = (ppi_included=="true") ? column_value.values : column_value.except!(*(ppi_headers-non_ppi_headers)).values
            csv << values
          end
          
          row = []
          csv << if ppi_included=="true"
            row.insert(0, order.number)  # Order Number
            row.insert(1, order&.store&.name) # Store Name
            row.insert(3, "UTC" ) # Time Zone
            row.insert(5, order.state) # Order State
            row.insert(37, (sale_analysis_discount.to_f.zero? ? 0 : sale_analysis_discount)) # Discount
            row.insert(38, order_subtotal)  # Order Subtotal
            row.insert(40, order.promo_code)  # Promo Code
          else
            row.insert(0, order.number)  # Order Number
            row.insert(1, order&.store&.name) # Store Name
            row.insert(3, "UTC" ) # Time Zone
            row.insert(4, order.local_date(order.completed_at)&.strftime("%B %d, %Y"))  # Date Placed
            row.insert(5, order.state) # Order State
            row.insert(26, (sale_analysis_discount.to_f.zero? ? 0 : sale_analysis_discount)) # Discount
            row.insert(27, order_subtotal) # Order Subtotal
            row.insert(29, order.promo_code) # Promo Code
          end
        end
      end
    end

    def extract_exchange_rate(to_currency, rates)
      rates.select{|ex| ex["name"].eql?(to_currency)}.first['value'].to_f
    end

    def download_csv(options = {})
      user, method_name, q, filename = options[:user], options[:method], options[:q], options[:filename]
      return if user.blank? || method_name.blank?
      reports_path = "public/user-reports"
      Dir.mkdir("#{reports_path}") unless Dir.exist?("#{reports_path}")
      FileUtils.rm_rf(Dir["#{reports_path}/*"])
      @file_path = "#{reports_path}/#{filename}"
      self.send(method_name, user, q)

      @password = user.report_password(user) if user.present?
      @password ||= ENV['ZIP_ENCRYPTION']
      Spree::Order.add_to_zip(@file_path, @password)
      "#{@file_path}.zip"
    end

    def local_date(date, timezone = 'UTC')
      date.present? ? date.in_time_zone(timezone) : nil
    end
  end
end
