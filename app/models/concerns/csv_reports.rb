module CsvReports
  attr_accessor :file_path, :password
  class << self
    def to_csv(user, q = {})
      vendor_dashboard_headers = ["Order number", "Storefront", "Timezone", "Date Placed", "Status", "Customer", "Currency", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Tax(inclusive)", "Tax(exclusive)", "Tags", "Total" ]
      headers = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Time Placed", "Order Status", "Customer Full Name", "Customer Address", "Customer First Name",  "Customer Last Name", "Shipping Delivery Country", "Customer Phone", "Customer Email", "Product name", "Brand Name", "Product Sku", "Vendor Sku","Barcode Number", "Variant", "Product quantity", "Product price", "Unit Cost Price" ,"Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Order currency", "Vendor Currency", "Exchange Rate", "Sub Total", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount amount","Order Subtotal" , "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Iso Number", "Special Message", "Card Type", "Recipient Name", "Recipients First Name", "Recipients Last Name" ,"Recipient Email", "Recipient Phone Number", "Marketing Enabled", "Product Tag", "Reference Number", "Notes / Comments" ]
      is_show_gift_card_column = user&.client&.show_gift_card_number
      headers.insert(headers.find_index("Gift Card Iso Number"),"Gift Card Number") if is_show_gift_card_column
      
      CSV.open("#{@file_path}.csv", "wb") do |csv|
        if user.spree_roles.map(&:name).include?"vendor"
          vendor = user&.vendors&.first
          q[:shipments_vendor_id_eq] = vendor&.id
          base_currency = vendor&.base_currency&.name
          q = Spree::Order.complete.ransack(q)
          orders = q.result(distinct: true).order("completed_at DESC")
          csv << vendor_dashboard_headers
          orders.each do |order|
            price_values = order.price_values(base_currency, vendor&.id)
            shipment = order.shipments.where(vendor_id: vendor&.id).first
            shipment_state = shipment&.state&.to_s
            csv_line = []
            csv_line << order.number
            csv_line << order&.store&.name
            csv_line << "UTC"
            csv_line << order&.completed_at&.strftime("%B %d, %Y")
            csv_line << shipment_state
            csv_line << order&.email
            csv_line << base_currency
            csv_line << shipment&.delivery_pickup_date&.strftime("%B %d, %Y")
            csv_line << shipment&.delivery_pickup_time
            csv_line << Spree::Order.local_date(shipment&.shipped_at)&.strftime("%B %d, %Y")
            csv_line << (shipment&.shipped_at)&.strftime("%I:%M %p")
            csv_line << price_values[:prices][:included_tax_total]
            csv_line << price_values[:prices][:additional_tax_total]
            csv_line << order&.order_tags&.pluck('label_name')&.join(',')
            csv_line << price_values[:prices][:payable_amount]
            csv << csv_line
          end
        else
          q[:shipments_vendor_id_in] = user&.client&.vendor_ids
          q = Spree::Order.complete.includes(:shipments, :line_items => [:sale_analysis, :givex_cards, :ts_giftcards]).ransack(q)
          orders = q.result(distinct: true).order("completed_at DESC")
          csv << headers
          orders.each do |order|
            shipment_state = order.shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
            sale_analysis_discount = order.tp(0)
            order_subtotal = order.tp(0)
            order.line_items.each_with_index do |line_item, index|
              sale_analysis = line_item.sale_analysis
              shipment = order.shipments.find_by(line_item_id: line_item.id)
              if index.zero?
                sale_analysis_discount = order.tp(sale_analysis&.discount_amount.to_f)
                order_subtotal = order.tp(sale_analysis&.order_subtotal.to_f)
              end
              csv_line = []
              csv_line << sale_analysis&.order_number
              csv_line << sale_analysis&.storefront
              csv_line << sale_analysis&.vendor
              csv_line << "UTC"
              csv_line << sale_analysis&.date_placed&.strftime("%B %d, %Y")
              csv_line << sale_analysis&.time_placed&.strftime("%I:%M %p")
              csv_line << sale_analysis&.order_status
              csv_line << sale_analysis&.customer_full_name
              csv_line << sale_analysis&.customer_address
              csv_line << sale_analysis&.customer_first_name
              csv_line << sale_analysis&.customer_last_name
              csv_line << sale_analysis&.shipping_delivery_country
              csv_line << sale_analysis&.customer_phone
              csv_line << sale_analysis&.customer_email
              csv_line << sale_analysis&.product_name
              csv_line << sale_analysis&.brand_name
              csv_line << sale_analysis&.product_sku
              csv_line << sale_analysis&.vendor_sku
              csv_line << sale_analysis&.barcode_number
              csv_line << sale_analysis&.variant
              csv_line << sale_analysis&.product_quantity
              csv_line << sale_analysis&.product_price
              csv_line << line_item.tp(sale_analysis&.unit_cost_price.to_f)
              csv_line << sale_analysis&.delivery_pickup_date&.strftime("%B %d, %Y")
              csv_line << sale_analysis&.delivery_pickup_time
              csv_line << order.local_date(shipment&.shipped_at)&.strftime("%B %d, %Y")
              csv_line << order.local_date(shipment&.shipped_at)&.strftime("%I:%M %p")
              csv_line << sale_analysis&.order_currency
              csv_line << sale_analysis&.vendor_currency
              csv_line << sale_analysis&.exchange_rate
              csv_line << sale_analysis&.sub_total
              csv_line << sale_analysis&.tax_inclusive
              csv_line << sale_analysis&.additional_tax
              csv_line << line_item.tp(sale_analysis&.shipping_amount || 0)
              csv_line << (index.zero? ? line_item.tp(sale_analysis&.total_shipping_amount || 0) : line_item.tp(0))
              csv_line << 0
              csv_line << ""
              csv_line << sale_analysis&.associated_order_value
              csv_line << ""
              csv_line << sale_analysis&.payment_method
              csv_line << sale_analysis&.shipping_method
              csv_line << shipment_state
              csv_line << sale_analysis&.tags
              csv_line << line_item&.gift_card_number if is_show_gift_card_column
              csv_line << line_item&.gift_card_iso_number
              csv_line << sale_analysis&.special_message
              csv_line << "#{sale_analysis&.product_card_type_with_ts_type}"
              csv_line << sale_analysis&.recipient_name
              csv_line << sale_analysis&.recipient_first_name
              csv_line << sale_analysis&.recipient_last_name
              csv_line << sale_analysis&.recipient_email
              csv_line << sale_analysis&.recipient_phone_number
              csv_line << sale_analysis&.marketing_enabled
              csv_line << sale_analysis&.product_tag
              csv_line << order.spo_invoice
              csv_line << order&.notes
              csv << csv_line
            end
            row = []
            row.insert(0, order.number)  # Order Number
            row.insert(1, order&.store&.name) # Store Name
            row.insert(3, "UTC" ) # Time Zone
            row.insert(4, order.local_date(order.completed_at)&.strftime("%B %d, %Y")) # Date Placed
            row.insert(5, order.local_date(order.completed_at)&.strftime("%I:%M %p")) # Time Placed
            row.insert(6, order&.state)  # Order Status
            row.insert(35, (sale_analysis_discount.to_f.zero? ? 0 : sale_analysis_discount))  # Discount amount
            row.insert(36, order_subtotal)  # Order Subtotal
            row.insert(38, order&.promo_code)  # Promo Code
            csv << row

          end
        end
      end
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

    def order_card_details(user, q = {})
      order = q[:order]
      card_types = ["tsgift_digital", "tsgift_physical", "tsgift_both", "givex_digital", "givex_physical", "givex_both"]
      headers = ["Order Number", "Product Name", "Giftcard Number", "Pin", "Currency", "Value"]

      CSV.open("#{@file_path}.csv", "wb") do |csv|
        csv << headers

        order.ts_giftcards.each do |card|
          csv << [
            order.number,
            card.line_item&.product&.name,
            card.number,
            card.pin,
            order.currency,
            order.tp(card.balance.to_f)
          ]
        end

        order.givex_cards.each do |card|
          csv << [
            order.number,
            card.line_item&.product&.name,
            card.givex_number,
            card.givex_transaction_reference&.split(':')&.[](1),
            order.currency,
            order.tp(card.balance.to_f)
          ]
        end
      end
    end

    def ts_givex_sales_csv(user, q = {})
      headers = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Time Placed", "Order Status", "Product name", "Product Sku", "Vendor Sku", "Variant", "Product quantity", "Product price", "Shipped Date", "Shipped Time", "Order currency", "Vendor Currency", "Exchange Rate", "Sub Total", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount amount", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Iso Number", "Bonus Card", "Card Type", "Marketing Enabled", "Product Tag"]
      is_show_gift_card_column = user&.client&.show_gift_card_number
      client =  user&.client
      headers.insert(headers.find_index("Gift Card Iso Number"),"Gift Card Number") if is_show_gift_card_column
      CSV.open("#{@file_path}.csv", "wb") do |csv|
          q[:shipments_vendor_id_in] = user&.client&.vendor_ids

          order_list = Spree::Order.complete.ransack(q).result(distinct: true)
          order_ids = order_list.joins(:ts_giftcards).ids + order_list.joins(:givex_cards).ids
          orders = order_list.where(id: order_ids).includes({ts_giftcards: [line_item: [:variant, :product]]}, {givex_cards: [line_item: [:variant, :product]]},
                   :calculated_price, :shipments,{payments: :payment_method}, :order_tags, :store,
                   line_items: [:calculated_price, {:variant=>{:product=>:vendor}}, :line_item_customizations, :line_item_exchange_rate]).order("completed_at DESC")
          csv << headers

          orders.find_all do |order|
            order.ts_giftcards.each { |card| gift_card_csv_row(card, csv,is_show_gift_card_column,client,order)}
            order.givex_cards.each { |card| gift_card_csv_row(card, csv,is_show_gift_card_column,client,order)}
          end
        end
    end

    def gift_card_csv_row(card, csv,is_show_gift_card_column,client,order)
      line_item = order.line_items.find{|item| item.id === card.line_item_id}
      variant = line_item&.variant
      product = line_item&.product if variant.present?
      shipment_state = order.shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
      payment_method = (order.calculated_price.present? ? order&.calculated_price&.meta[:payment_method] : "")
      promo_code = (order.calculated_price.present? ? order.calculated_price[:meta][:promo_code] : "")
      order_attrs = (order.calculated_price.present? ? order.calculated_price.calculated_value : "")
      shipments = order_attrs[:shipments] if order_attrs.present?
      enabled_marketing = (card.order.enabled_marketing ? 'Yes' : card.order.news_letter ? 'Default' : 'No')
      line_item_price_values = line_item&.calculated_price&.calculated_value
      item_shipmnent  = (shipments.present? ? shipments.find{|shipment| shipment&.line_item_id === line_item&.id} : nil)
      number_display = card.respond_to?(:givex_number) ? card.givex_number : card.number
      csv_line = []
      csv_line << order.number
      csv_line << order&.store&.name
      csv_line << ((product.present? && variant.present?) ? product&.vendor&.name : "")
      csv_line << "UTC"
      csv_line << Spree::Order.local_date(order.completed_at).strftime("%B %d, %Y")
      csv_line << Spree::Order.local_date(order.completed_at).strftime("%I:%M %p")
      csv_line << order.state
      csv_line << ((product.present? && variant.present?) ? variant&.name : "")
      csv_line << ((product.present? && variant.present?) ? variant&.sku : "")
      csv_line << ((product.present? && variant.present?) ? product&.vendor_sku : "")
      csv_line << (line_item.present? && line_item&.calculated_price.present? ? line_item&.calculated_price&.meta[:options_text] : "")
      csv_line << 1
      csv_line << (card.bonus ? card.balance : (line_item_price_values.present? ?  line_item_price_values[:sub_total] : 0.0 ))
      csv_line << Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%B %d, %Y")
      csv_line << Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%I:%M %p")
      csv_line << (line_item.present? ? line_item.line_item_exchange_rate&.to_currency : "")
      csv_line << (line_item.present? ? line_item.line_item_exchange_rate&.from_currency : "")
      csv_line << (line_item.present? ? line_item.line_item_exchange_rate&.exchange_rate : "")
      csv_line << (card.bonus ? card.balance : (line_item_price_values.present? ? line_item_price_values[:sub_total] : 0.0 ))
      csv_line << (line_item.blank? ||  line_item_price_values.blank? || line_item_price_values[:included_tax_total].nil? ? "0.00" : line_item.tp(line_item_price_values[:included_tax_total]))
      csv_line << (line_item.blank? ||  line_item_price_values.blank? || line_item_price_values[:additional_tax_total].nil? ? "0.00" : line_item.tp(line_item_price_values[:additional_tax_total]))
      csv_line << (line_item.blank? || order_attrs.blank? || (order_attrs[:prices][:vendor_based_shipment][line_item.vendor_id].to_f).nil? ? "0.00" : order.tp(order_attrs[:prices][:vendor_based_shipment][line_item.vendor_id].to_f))
      csv_line << (order_attrs.present? ? line_item.tp(order_attrs[:prices][:ship_total]) : "")
      csv_line << (order_attrs.present? ? order_attrs[:prices][:promo_total] : "")
      csv_line << (order_attrs.present? ? order_attrs[:prices][:total] : "")
      csv_line << promo_code
      csv_line << payment_method
      csv_line << (line_item.present? && line_item&.calculated_price.present? ? line_item&.calculated_price&.meta[:shipping_method_name] : "")
      csv_line << shipment_state
      csv_line << order&.order_tags&.pluck('label_name')&.join(',')
      csv_line << card&.is_gift_card_number_display(number_display,client) if is_show_gift_card_column
      if card.class.name == "Spree::GivexCard"
        iso_number = card.iso_code.blank? ? (card&.givex_number[-10..-2] rescue "") : card.iso_code&.split("-")&.last.to_s
      else
        iso_number = card&.serial_number
      end
      csv_line << iso_number
      csv_line << (card.bonus ? 'Yes' : 'No')
      csv_line << (line_item.present? ? line_item.delivery_mode : "")
      csv_line << enabled_marketing
      csv_line << (line_item&.calculated_price&.present? ? line_item.calculated_price.meta[:tag_list] : "")
      csv << csv_line
    end

    # Sale Report for Accounts (requested by finance dept)
    def to_csv_finance(user, q = {})
      # Showing zero shipment cost for line items as new row with order's shipping cost added against every order
      vendor_dashboard_headers = ["Order number", "Storefront", "Timezone", "Date Placed", "Status", "Customer", "Currency", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Tax(inclusive)", "Tax(exclusive)", "Tags", "Total"]
      headers = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Time Placed", "Order Status", "Customer Full Name", "Customer Address", "Customer First Name",  "Customer Last Name", "Shipping Delivery Country", "Customer Phone", "Customer Email", "Product name", "Product Sku", "Vendor Sku", "Variant", "Product quantity", "Product price", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Order currency", "Vendor Currency", "Exchange Rate", "Sub Total", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount amount", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Number", "Special Message", "Card Type", "Recipient Name", "Recipients First Name", "Recipients Last Name" ,"Recipient Email", "Recipient Phone Number", "Marketing Enabled", "Product Tag"]
      CSV.open("#{@file_path}.csv", "wb") do |csv|
        if user.spree_roles.map(&:name).include?"vendor"
          vendor = user&.vendors&.first
          q[:shipments_vendor_id_eq] = vendor&.id
          base_currency = vendor&.base_currency&.name
          q = Spree::Order.complete.ransack(q)
          orders = q.result(distinct: true).order("completed_at DESC")
          csv << vendor_dashboard_headers
          orders.each do |order|
            price_values = order.price_values(base_currency, vendor&.id)
            shipment = order.shipments.where(vendor_id: vendor&.id)
            shipment_state = shipment&.state&.to_s
            csv_line = [order.number, order&.store&.name, "UTC", order&.completed_at&.strftime("%B %d, %Y"), shipment_state, order&.email, base_currency,
                        shipment&.delivery_pickup_date&.strftime("%B %d, %Y"),(shipment&.shipped_at)&.strftime("%I:%M %p"), price_values[:prices][:included_tax_total],
                         price_values[:prices][:additional_tax_total], order&.order_tags&.pluck('label_name')&.join(','), price_values[:prices][:payable_amount]]
            csv << csv_line
          end
        else
          q[:shipments_vendor_id_in] = user&.client&.vendor_ids
          q = Spree::Order.complete.ransack(q)
          orders = q.result(distinct: true).order("completed_at DESC")
          csv << headers
          orders.each do |order|
            billing_address = order.billing_address
            shipment_state = order.shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
            payment_method = order.payments.completed.map {|k| k.payment_method.name}.join(', ')
            promo_code = order&.promotions&.map(&:code)&.join(", ")
            customer_email = order.user&.email || order.email
            order_attrs = order.price_values
            @line_items = order_attrs[:line_items]
            @shipments = order_attrs[:shipments]
            customer_name = billing_address&.full_username
            enabled_marketing = (order.enabled_marketing ? 'Yes' : order.news_letter ? 'Default' : 'No')
            @line_items.each do |line_item|
              item_shipmnent = @shipments.find_by(line_item_id: line_item.id)
              gift_cards_rows =  finance_sale_cards_csv_row(line_item.ts_giftcards,order,billing_address,shipment_state,payment_method,promo_code,
                                                            customer_email,order_attrs,customer_name,enabled_marketing,item_shipmnent,line_item) if line_item.ts_giftcards.present?

              givex_cards_rows = finance_sale_cards_csv_row(line_item.givex_cards,order,billing_address,shipment_state,payment_method,promo_code,
                                                            customer_email,order_attrs,customer_name,enabled_marketing,item_shipmnent,line_item)  if line_item.givex_cards.present?
              next if line_item.variant.blank? || line_item.product.blank?
              voucher_recipent_name = line_item&.line_item_customizations&.where(name: 'Gift Card Name')&.first&.try(:value)
              # default lineitem data without card
                csv_line = [
                  order.number, order&.store&.name, line_item&.product&.vendor&.name, "UTC", Spree::Order.local_date(order.completed_at).strftime("%B %d, %Y"),
                  Spree::Order.local_date(order.completed_at).strftime("%I:%M %p"), order.state, customer_name, billing_address&.get_full_address,
                  billing_address&.firstname,billing_address&.lastname, order.ship_address&.country&.name,billing_address&.phone,customer_email,line_item&.variant&.name,
                  line_item&.variant&.sku,line_item.product.vendor_sku, line_item&.options_text,line_item&.quantity,
                  line_item.exchanged_prices[:sub_total], item_shipmnent&.delivery_pickup_date&.strftime("%B %d, %Y"),item_shipmnent&.delivery_pickup_time,
                  Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%B %d, %Y"), Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%I:%M %p"), line_item.line_item_exchange_rate&.to_currency, line_item.line_item_exchange_rate&.from_currency,
                  line_item.line_item_exchange_rate&.exchange_rate, line_item.exchanged_prices[:amount],
                  line_item.tp(line_item.total_tax(:included)),
                  line_item.tp(line_item.total_tax(:additional)),
                  order.tp(order.exchanged_prices[:vendor_based_shipment][line_item.vendor_id]),
                  0, order.exchanged_prices[:promo_total], order.exchanged_prices[:total], promo_code, payment_method,line_item.shipping_method_name, shipment_state,order&.order_tags&.pluck('label_name')&.join(','),
                  "#{line_item.gift_card_number}", line_item.message, line_item.delivery_mode, (line_item.is_gift_card? ? voucher_recipent_name : "#{line_item.receipient_first_name} #{line_item.receipient_last_name}"), (line_item.is_gift_card? ? voucher_recipent_name : line_item.receipient_first_name),
                  (line_item.is_gift_card? ? voucher_recipent_name : line_item.receipient_last_name), (line_item.is_gift_card? ? line_item&.line_item_customizations&.where(name: 'Gift Card Email')&.first&.try(:value) : line_item.receipient_email),
                  line_item&.receipient_phone_number, enabled_marketing, line_item&.product&.tag_list&.first]
                # insert line_item if cards are blank
                if gift_cards_rows.blank? && givex_cards_rows.blank?
                  csv << csv_line
                else
                  # insert gift card rows
                  gift_cards_rows.each do |gift_card_row|
                    csv << gift_card_row
                  end if gift_cards_rows.present?

                  # insert givex card rows
                  givex_cards_rows.each  do |givex_card_row|
                    csv << givex_card_row
                  end if givex_cards_rows.present?
                end
            end
            csv << [].insert(31, order.exchanged_prices[:ship_total])
          end
        end
      end
    end

    def finance_sale_cards_csv_row(cards,order,billing_address,shipment_state,payment_method,promo_code,
      customer_email,order_attrs,customer_name,enabled_marketing,item_shipmnent,line_item)
      return if cards.blank? || line_item.product.blank?
      rows = [];
      cards.each do |card|
        row = [ order.number, order&.store&.name, line_item&.product&.vendor&.name, "UTC", Spree::Order.local_date(order.completed_at).strftime("%B %d, %Y"),
          Spree::Order.local_date(order.completed_at).strftime("%I:%M %p"), order.state, customer_name, billing_address&.get_full_address,
          billing_address&.firstname,billing_address&.lastname, order.ship_address&.country&.name,billing_address&.phone,customer_email,line_item&.variant&.name,
          line_item&.variant&.sku,line_item.product.vendor_sku, line_item&.options_text,line_item&.quantity,
          line_item.exchanged_prices[:sub_total], item_shipmnent&.delivery_pickup_date&.strftime("%B %d, %Y"),item_shipmnent&.delivery_pickup_time,
          Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%B %d, %Y"), Spree::Order.local_date(item_shipmnent&.shipped_at)&.strftime("%I:%M %p"), line_item.line_item_exchange_rate&.to_currency, line_item.line_item_exchange_rate&.from_currency,
          line_item.line_item_exchange_rate&.exchange_rate, line_item.exchanged_prices[:amount],
          line_item.tp(line_item.total_tax(:included)),
          line_item.tp(line_item.total_tax(:additional)),
          order.tp(order.exchanged_prices[:vendor_based_shipment][line_item.vendor_id]),
          0, order.exchanged_prices[:promo_total], order.exchanged_prices[:total], promo_code, payment_method,line_item.shipping_method_name, shipment_state,order&.order_tags&.pluck('label_name')&.join(','),
          (card.respond_to?(:number) ? card.number : card.givex_number), line_item.message, line_item.delivery_mode, (line_item.is_gift_card? ? voucher_recipent_name : "#{line_item.receipient_first_name} #{line_item.receipient_last_name}"), (line_item.is_gift_card? ? voucher_recipent_name : line_item.receipient_first_name),
          (line_item.is_gift_card? ? voucher_recipent_name : line_item.receipient_last_name), (line_item.is_gift_card? ? line_item&.line_item_customizations&.where(name: 'Gift Card Email')&.first&.try(:value) : line_item.receipient_email),
          line_item&.receipient_phone_number, enabled_marketing, line_item&.product&.tag_list&.first]
        rows.push(row);
      end
      return rows
    end

    def combined_cards_report(options = {})
      count=0
      file_path = options[:path]
      headers = ["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Time Placed", "Order Status", "Product name", "Product Sku", "Vendor Sku", "Variant", "Product quantity", "Product price", "Delivery/Pick-up Date", "Delivery/Pick-up Time", "Shipped Date", "Shipped Time", "Order currency", "Vendor Currency", "Exchange Rate", "Sub Total", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount amount", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Iso Number", "Bonus Card", "Card Type", "Marketing Enabled", "Product Tag"]  
      CSV.open("#{file_path}.csv", "wb") do |csv|

        ts = Spree::TsGiftcard.joins(order: :store).where("spree_stores.test_mode = ? AND spree_orders.completed_at >= ? AND spree_orders.completed_at <= ?", false, options[:start_datetime], options[:end_datetime])
        givex = Spree::GivexCard.joins(order: :store).where("spree_stores.test_mode = ? AND spree_orders.completed_at >= ? AND spree_orders.completed_at <= ?", false, options[:start_datetime], options[:end_datetime])
        order_ids = ts.pluck(:order_id) + givex.pluck(:order_id)
        order_ids.uniq!
        orders = Spree::Order.where(id: order_ids).includes({ts_giftcards: [line_item: [:variant, :product]]}, {givex_cards: [line_item: [:variant, :product]]},
          :calculated_price, :shipments,{payments: :payment_method}, :order_tags, :store,
          line_items: [:calculated_price, {:variant=>{:product=>:vendor}}, :line_item_customizations, :line_item_exchange_rate]).order("completed_at DESC")

        
        csv << headers
        orders.find_all do |order|
          client = order.store.client
          order.ts_giftcards.each do |card|
            gift_card_csv_row(card, csv,false,client,order)
            count+=1
          end
          order.givex_cards.each do |card| 
            gift_card_csv_row(card, csv,false,client,order)
            count+=1
          end
        end
        
      end
      ["#{file_path}.csv", count]
    end

    def combined_sales_report(options)
      count = 0
      start_datetime, end_datetime, file_path = options[:start_datetime], options[:end_datetime], options[:path]

      headers=["Order number", "Storefront", "Vendor", "Vendor Timezone", "Date Placed", "Order Status", "Product name", "Brand Name", "Product Sku", "Vendor Sku", "Barcode Number" ,"Variant", "Product quantity", "Product price","Unit Cost Price" ,"Order currency", "Vendor Currency", "Exchange Rate", "Sub Total","Report Currency sub Total", "Report Currency Code", "Report Currency Exchange Rate", "Tax(inclusive)", "Tax(exclusive)", "Shipping amount", "Total Shipping amount", "Discount Amount","Order Subtotal", "Associated Order Value" ,"Promo Code",  "Order payment method", "Shipping Method", "Order shipped", "Tags", "Gift Card Number", "Gift Card Iso Number", "Card Type", "Marketing Enabled", "Product Tag", "Reference Number", "Notes / Comments"]
      CSV.open("#{file_path}.csv", "wb") do |csv|
        q = {completed_at_gteq: start_datetime, completed_at_lteq: end_datetime}
        q = Spree::Order.joins(:store).where(spree_stores:{test_mode: false}).complete.includes(:store, :shipments, :line_items => [:sale_analysis, :givex_cards, :ts_giftcards]).ransack(q)
        orders = q.result(distinct: true).order("completed_at DESC")
        csv << headers
        orders.each do |order|
          client = order.store.client
          shipments = order.shipments
          shipment_state = shipments.all?{ |s| s.state == "shipped" }? "Yes" : "No"
          sale_analysis_discount = order.tp(0)
          order_subtotal = order.tp(0)
          order.line_items.each_with_index do |line_item, index|
            item_shipmnent = shipments&.find_by(line_item_id: line_item&.id)
            exchange_value = line_item&.saved_exchange_rate || 1
            shipping_amount = (item_shipmnent&.cost.to_f * exchange_value)
            sale_analysis = line_item.sale_analysis
            if index.zero?
              sale_analysis_discount = line_item.tp(sale_analysis&.discount_amount.to_f)
              order_subtotal = line_item.tp(sale_analysis&.order_subtotal.to_f)
            end
            column_value = {
              'Order number' => sale_analysis&.order_number,
              'Storefront' => sale_analysis&.storefront,
              'Vendor' => sale_analysis&.vendor,
              'Vendor Timezone' => client&.timezone,
              'Date Placed' => sale_analysis&.date_placed&.strftime("%B %d, %Y"),
              'Order Status' => sale_analysis&.order_status,
              'Product name' => sale_analysis&.product_name,
              'Brand Name' => sale_analysis&.brand_name,
              'Product Sku' => sale_analysis&.product_sku,
              'Vendor Sku' => sale_analysis&.vendor_sku,
              'Barcode Number' => sale_analysis&.barcode_number,
              'Variant' => sale_analysis&.variant,
              'Product quantity' => sale_analysis&.product_quantity,
              'Product price' => sale_analysis&.product_price,
              'Unit Cost Price' => line_item.tp(sale_analysis&.unit_cost_price.to_f),
              'Order currency' => sale_analysis&.order_currency,
              'Vendor Currency' => sale_analysis&.vendor_currency,
              'Exchange Rate' => sale_analysis&.exchange_rate,
              'Sub Total' => sale_analysis&.sub_total,
              'Report Currency sub Total' => line_item.tp((sale_analysis&.sub_total.to_f)*(client.reporting_exchange_rate(order.currency))),
              'Report Currency Code' => client&.reporting_currency,
              'Report Currency Exchange Rate' => client.reporting_exchange_rate(order.currency),
              'Tax(inclusive)' => sale_analysis&.tax_inclusive,
              'Tax(exclusive)' => sale_analysis&.additional_tax,
              'Shipping amount' => (line_item.tp(sale_analysis&.shipping_amount.to_f)),
              'Total Shipping amount' => (index.zero? ? line_item.tp(sale_analysis&.total_shipping_amount) : line_item.tp(0)),
              'Discount Amount' => 0,
              'Order Subtotal' => "",
              'Associated Order Value' => sale_analysis&.associated_order_value,
              'Promo Code' => "",
              'Order payment method' => sale_analysis&.payment_method,
              'Shipping Method' => sale_analysis&.shipping_method,
              'Order shipped' => shipment_state,
              'Tags' => order&.order_tags&.pluck('label_name')&.join(','),
              'Gift Card Number' => line_item_gc_number(line_item),
              'Gift Card Iso Number' => line_item&.gift_card_iso_number,
              'Card Type' => "#{sale_analysis&.product_card_type_with_ts_type}",
              'Marketing Enabled' => sale_analysis&.marketing_enabled,
              'Product Tag' => sale_analysis&.product_tag,
              'Reference Number' => order.spo_invoice,
              'Notes / Comments' => order&.notes
            }
            csv << column_value.values
            count+=1
          end
          row = []
          row.insert(0, order.number)  # Order Number
          row.insert(1, order&.store&.name) # Store Name
          row.insert(3, "UTC" ) # Time Zone
          row.insert(4, order.local_date(order.completed_at)&.strftime("%B %d, %Y"))  # Date Placed
          row.insert(5, order.state) # Order State
          row.insert(26, (sale_analysis_discount.to_f.zero? ? 0 : sale_analysis_discount)) # Discount
          row.insert(27, order_subtotal) # Order Subtotal
          row.insert(29, order.promo_code) # Promo Code
          csv << row
        end
      end
      ["#{file_path}.csv",count]
    end

    def line_item_gc_number(line_item)
      return nil unless line_item.present?
      delivery_type = line_item.delivery_mode

      card_numbers = if delivery_type == 'givex_digital' || delivery_type == 'givex_physical'
        line_item.givex_cards.map(&:givex_number)
      elsif delivery_type == 'tsgift_digital' || delivery_type == 'tsgift_physical'
        line_item.ts_giftcards.map(&:number)
      elsif line_item.is_gift_card
        Spree::GiftCard.where(line_item_id: line_item.id).map(&:code)
      end
      
      card_numbers&.reject(&:blank?)&.map{ |number| '*' * 20 + number.to_s.chars.last(4).join }&.join(', ')
    end
  end
end
