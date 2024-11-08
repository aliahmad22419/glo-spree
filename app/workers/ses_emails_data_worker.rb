class SesEmailsDataWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'ses_emails_data'

  def perform resource_id, type, report_id=nil, ssl_details=nil
    if type == "order_confirmation_customer"
      order = Spree::Order.find_by('spree_orders.id = ?', resource_id)
      store = order.store
      config = store.email_config({type: 'confirm'})
      attrs = order.price_values(nil, nil)
      total_line_items = attrs[:line_items]
      data = vendor_confirmation(order, store, config, attrs, total_line_items)
      to_addresses = [order.email]
      cc_addresses = (store.recipient_emails&.split(',')&.map(&:strip) rescue [])&.reject { |c| c.empty? }
      bcc_addresses = (store.enable_review_io ? [store.reviews_io_bcc_email] : [])&.reject { |c| c.empty? }
      from_address = store&.mail_from_address
      template = "order_confirmation_customer_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
    elsif  type == "order_confirmation_vendor"
      order = Spree::Order.find_by('spree_orders.id = ?', resource_id)
      store = order.store
      vendors = order.line_items.map{ |item| item.vendor }.compact.uniq
      vendors.each do |vendor|
        config = store.email_config({type: 'vendor'})
        attrs = order.price_values(nil, vendor.id)
        total_line_items = attrs[:line_items]
        intimation_emails = ""
        total_line_items.each do |line_item|
          intimation_emails = intimation_emails.to_s + line_item.product&.intimation_emails.to_s + ","
        end
        data = vendor_confirmation(order, store, config, attrs, total_line_items)
        vendor_line_items = order.price_values(nil, vendor.id)[:line_items]
        inclusive_tax_vendor_total = vendor_line_items.sum{|li| li.exchanged_prices[:included_tax_total].to_f} rescue 0.00
        additional_tax_total = vendor_line_items.sum{|li| li.exchanged_prices[:additional_tax_total].to_f} rescue 0.00
        data[:vendor_name] = vendor.name
        data[:vendor_ship_total] = order.display_exchanged(order.price_values[:prices][:vendor_based_shipment][vendor.id]) rescue ""
        data[:vendor_tax_total] = order.display_exchanged(inclusive_tax_vendor_total) rescue ""
        data[:vendor_exclusive_tax_total] = order.display_exchanged(additional_tax_total) rescue ""
        data[:show_vendor_exclusive_tax_total] = additional_tax_total.to_f > 0.0 rescue ""
        data[:show_vendor_inclusive_tax_total] = inclusive_tax_vendor_total.to_f > 0.0 rescue ""


        data = convert_nil_to_string(data)
        to_addresses = [vendor.email]
        cc_addresses = ((store&.recipient_emails&.split(',')&.map(&:strip) || []) + intimation_emails&.split(',')&.map(&:strip) +  (vendor&.additional_emails&.split(',')&.map(&:strip) || []))&.uniq&.reject { |c| c.empty? }
        bcc_addresses = (store&.bcc_emails&.split(',')&.map(&:strip) || []).uniq&.reject { |c| c.empty? }
        from_address = store&.mail_from_address
        template = "order_confirmation_vendor_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
        send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
      end
    elsif  type == "regular_shipment_customer"
      shipment = Spree::Shipment.find_by('spree_shipments.id = ?', resource_id)
      order = shipment.order
      store = order.store
      return if store.preferred_disable_shipping_notification
      config = store.email_config({type: 'shipping'})
      attrs = order.price_values(nil, shipment.vendor_id)
      line_items = attrs[:line_items]
      line_item_ids = shipment.line_items.map(&:id)
      total_line_items = line_items.select { |line_item| line_item_ids.include?(line_item.id)}
      data = vendor_confirmation(order, store, config, attrs, total_line_items)
      data[:shipping_method] = shipment.shipping_method.name
      data[:tracking_url] = shipment.tracking_url
      data[:tracking_number] = shipment.tracking
      data[:receipient_first_name] = total_line_items&.last&.receipient_first_name
      data[:receipient_last_name] = total_line_items&.last&.receipient_last_name
      data[:sender_name] = total_line_items&.last&.sender_name.present? ? total_line_items&.last&.sender_name : data[:sender_name]
      data[:receipient_email] = total_line_items&.last&.receipient_email
      data[:ship_all_digitals] = shipment.all_digital?
      data[:ship_all_physicals] = shipment.all_physical?
      data[:ship_all_simple] = shipment.all_simple?
      data[:ship_all_food] = shipment.all_food?
      data = convert_nil_to_string(data)
      to_addresses = [order.email]
      cc_addresses = (store.recipient_emails&.split(',')&.map(&:strip) rescue [])&.reject { |c| c.empty? }
      bcc_addresses = (store&.bcc_emails&.split(',')&.map(&:strip) || []).uniq&.reject { |c| c.empty? }
      from_address = store&.mail_from_address
      template = "regular_shipment_customer_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
    elsif  type == "voucher_confirmation_customer" || type == "voucher_confirmation_recipient"
      gift_card = Spree::GiftCard.find_by('spree_gift_cards.id = ?', resource_id)
      order = gift_card.line_item.order
      store = order.store
      if type == "voucher_confirmation_recipient"
        data = voucher_confirmation(gift_card, order, store, "voucher_confirmation_recipient")
        to_addresses = [gift_card.email]
        cc_addresses = []
        template = "voucher_confirmation_recipient_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      else
        data = voucher_confirmation(gift_card, order, store, "voucher_confirmation_customer")
        to_addresses = [order.email]
        cc_addresses = (store.recipient_emails&.split(',')&.map(&:strip) rescue [])
        template = "voucher_confirmation_customer_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      end
      from_address = store&.mail_from_address
      bcc_addresses = []
      send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
    elsif  type == "digital_ts_card_recipient"
      card = Spree::TsGiftcard.find_by('spree_ts_giftcards.id = ?', resource_id)
      ts_response = JSON.parse(card.response)
      line_item = card&.line_item
      email_change = line_item.email_changes.latest
      to_email = if email_change&.present? && !card.bonus
                   email_change.next_email
                 else
                   card.customer_email
                 end
      order = card.order
      store = order.store
      image_url = ''
      if ts_response["value"]["card_type"] == "monetary"
        template = "digital_ts_card_monetary_recipient_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      else
        template = "digital_ts_card_experiences_recipient_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      end
      client_address = get_client_address(store&.client)
      store_logo_url = get_store_logo_url(store)
      data = card.generate_ts_gift_card
      data.merge!(client_address: client_address, store_logo_url: store_logo_url)
      data = convert_nil_to_string(data)
      to_addresses = [to_email]
      cc_addresses = []
      bcc_addresses = []
      from_address = store&.mail_from_address
      send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
    elsif  type == "digital_givex_card_recipient"
      givex_card = Spree::GivexCard.find_by('spree_givex_cards.id = ?', resource_id)

      to_email = if givex_card.line_item&.email_changes&.latest.present? && !givex_card.bonus
         givex_card.line_item.email_changes.latest.next_email
      else
        givex_card.customer_email
      end

      order = givex_card&.order
      store = order&.try(:store) || givex_card&.try(:store)
      data = givex_card.generate_givex_data
      data = convert_nil_to_string(data)
      to_addresses = [to_email]
      cc_addresses = []
      bcc_addresses = []
      from_address = store&.mail_from_address
      template = "digital_givex_recipient_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
    elsif type.eql? "monthly_sale_report"
      store = Spree::Store.find_by('spree_stores.id = ?', resource_id)
      report_url = "https://" + store.url + "/reports/finance_report?report_id=#{report_id}"
      data = {report_url: report_url, store_name: store.name, logo_url: store.email_logo_url}
      to_addresses = str_to_a(store.finance_report_to)
      cc_addresses = str_to_a(store.finance_report_cc)
      bcc_addresses = []
      from_address = store&.mail_from_address
      template = "monthly_sale_report_store_" + ENV['SES_ENV'] + "_" + store.id.to_s
      send_emails(template, data, to_addresses, cc_addresses, bcc_addresses, from_address)
    elsif type  == "iframe_otp_verification"
      user = Spree::User.find_by_id(resource_id)
      template = "iframe_otp_verification"
      data = {otp: user&.active_otp&.otp_code, user_name: user&.email, store_name: user&.client&.stores&.first&.name}
      to_addresses = [user&.email]
      from_address = "noreply@techsembly.com"
      cc_addresses = ["hafizhassan.saleem@sabre.com", "hassanadssouser@gmail.com", "ayesha@plerosys.com", "ayesha@techsembly.com"]
      send_emails(template, data, to_addresses, cc_addresses, [], from_address)
    elsif type  == "iframe_dns_details"
      store = Spree::Store.find_by_id(resource_id)
      template = "iframe_dns_details"
      ssl_data = []
      ssl_details["ssl_certificates"].each do |certificate|
        ssl_data << {name: certificate["resource_record"]["name"], type: certificate["resource_record"]["type"], value: certificate["resource_record"]["value"]}
      end
      product_name = store&.products&.first&.name
      store_url = "https://#{store.url}"
      store_logo_url = get_store_logo_url(store)
      client_address = get_client_address(store&.client)
      ssl_details["to_addresses"].split(',').each do |to_address|
        data = {user_name: to_address, product_name: product_name, store_url: store_url, cname: ssl_details["cname"], ssl_certificates: ssl_data, client_address: client_address, store_logo_url: store_logo_url}
        from_address = "noreply@techsembly.com"
        send_emails(template, data, [to_address], [], [], from_address)
      end
    end

  end

  def voucher_confirmation(gift_card, order, store, type)
    line_item = gift_card.line_item
    product = line_item&.product
    line_item_data = {}
    line_item_data[:product_name] = line_item.variant&.product&.name
    line_item_data[:quantity] = line_item.quantity
    line_item_data[:sub_total] = order.display_exchanged(gift_card.original_value)
    if type == "voucher_confirmation_recipient"
      line_item_data[:image_url] = 'https://static.techsembly.com/CFHEcLJjtnY2SbKzdSsrypQB'
      if product&.variants || line_item&.variant&.images.present?
        img = line_item&.variant&.images&.sort_by{|i|[i.sort_order,i.id]}&.reverse&.first
        line_item_data[:image_url] = img&.active_storge_url(img&.attachment)
      end
    else
      line_item_data[:image_url] = line_item_image_url line_item, store
    end
    sale_tax= (line_item.included_tax_total.to_f)/line_item.quantity
    bill_address = order.bill_address
    bill_address_attributes = convert_nil_to_string(bill_address.attributes)

    data = {line_item: line_item_data, recipient_email: gift_card.email, recipient_email_link: line_item.product&.recipient_email_link, message: line_item.message.to_s, sales_tax: sale_tax,
            grand_total: order.display_exchanged(line_item.sub_total), bill_address: bill_address_attributes,
            bill_address_country: bill_address.country.name, recipient_name: gift_card.name, created_at: gift_card.created_at.strftime('%d/%m/%y'),
            code: gift_card.code, store_url: "https://#{store&.url}", product_slug: line_item.slug, language: store&.preferred_default_language || 'en' }
    return convert_nil_to_string(data)
  end

  def vendor_confirmation(order, store, config, attrs, total_line_items)
    title = config[:title]&.html_safe || "Your have a new order!"
    description = config[:description]&.html_safe || "Once you have dispatched the order, please log in to your vendor dashboard to input the tracking URL and ID so your customers can track their shipment."
    completed_date = order.completed_at.strftime("%d %B %Y") rescue ""
    shipments = attrs[:shipments]
    gift_card_total = order.display_exchanged(:gc_total)
    order_total = order.display_exchanged((order.exchanged_prices[:payable_amount].to_f + order.total_applied_gift_card))
    item_total = order.display_exchanged(:item_total)
    ship_total =  order.display_exchanged(order.price_values[:prices][:ship_total]) || order.currency + " " + Spree::Money.new(order.currency).currency.symbol + " " + order.price_values[:prices][:ship_total] rescue " "
    ship_address = order.ship_address
    bill_address = order.bill_address
    line_items = []
    store_url = "https://#{store.url}"
    total_line_items.each do |line_item|
      line_item_data = {}
      line_item_data[:name] = "#{line_item.product&.vendor&.name&.upcase} : #{line_item.variant&.product&.name&.upcase}"
      line_item_data[:vendor_name] = line_item.product&.vendor&.name
      line_item_data[:product_name] = line_item.variant&.product&.name
      line_item_data[:terms_and_conditions] = line_item.variant&.product&.preferred_terms_and_conditions
      line_item_data[:quantity] = line_item.quantity
      line_item_data[:digital] = DIGITAL_TYPES.include?line_item.delivery_mode
      line_item_data[:physical] = PHYSICAL_TYPES.include?line_item.delivery_mode
      line_item_data[:receipient_first_name] = line_item.receipient_first_name
      line_item_data[:receipient_last_name] = line_item.receipient_last_name
      line_item_data[:sender_name] = line_item.sender_name
      line_item_data[:receipient_email] = line_item.receipient_email
      line_item_data[:gift_message] = line_item.message
      line_item_data[:recipient_email_link] = line_item.product&.recipient_email_link
      line_item_data[:line_item_formatted_amount] = line_item.display_exchanged(line_item.price_values[:amount])
      line_item_data[:product_exist] = ["033115"]&.include?line_item&.product&.sku
      line_item_data[:option_values] = []
      line_item.variant&.option_values&.each do |var_opt|
        line_item_data[:option_values].push({value: "#{var_opt.option_type&.name} : #{var_opt.name}"})
      end
      line_item_data[:customizations] = []
      customizations = line_item.line_item_customizations.joins(:customization).order("spree_customizations.order, spree_customizations.updated_at ASC")
      customizations.each do |personalization|
        line_item_data[:customizations].push({value: "#{personalization.name} : #{personalization.text.eql?("Customize (add additional amount to card)") ? line_item.display_exchanged(line_item.custom_price) : line_item.display_exchanged(personalization.text)}"})
      end
      line_item_shipment_id = line_item&.inventory_units&.first&.shipment_id
      shipment = shipments.select { |s| s.id.eql?(line_item_shipment_id) rescue nil }[0].try(:selected_shipping_rate)
      if shipment.present?
        pickup_date = shipment.shipment.delivery_pickup_date.strftime("%d %B %Y") rescue ""

        line_item_data[:internal_shiping_name] = shipment&.shipping_method&.admin_name
        line_item_data[:shipment_name] = shipment.name
        line_item_data[:shipment_pickup_date] = pickup_date
        line_item_data[:shipment_pickup_time] = shipment.shipment.delivery_pickup_time
        line_item_data[:shipment_cost] = line_item.display_exchanged(shipment.cost.to_f * line_item.saved_exchange_rate)
      end

      line_item_data[:sub_total] = line_item.display_exchanged(:amount)
      line_item_data[:image_url] = line_item_image_url line_item, store
      line_items.push(line_item_data)
    end
    all_digitals = order.all_digital?
    all_physicals =  order.all_physical?
    mix_products = all_digitals == false && all_physicals == false
    order_attributes = convert_nil_to_string(order.attributes)
    bill_address_attributes = convert_nil_to_string(bill_address.attributes)
    ship_address_attributes = convert_nil_to_string(ship_address.attributes)
    exclusive_tax = order.display_exchanged(order.price_values[:prices][:additional_tax_total]) ||  order.currency + " " + Spree::Money.new(order.currency).currency.symbol + " " + order.price_values[:prices][:additional_tax_total] rescue ""
    inclusive_tax = order.display_exchanged(order.price_values[:prices][:included_tax_total]) || order.currency + " "  + Spree::Money.new(order.currency).currency.symbol + " " + order.price_values[:prices][:included_tax_total]
    sender_name = (store.preferences[:store_type].eql?("iframe") && order&.line_items&.first&.sender_name.empty?) ? order&.line_items&.first&.receipient_first_name : order&.line_items&.first&.sender_name
    client_address = get_client_address(store&.client)
    store_logo_url = get_store_logo_url(store)
    line_item = order.line_items.last
    variant = line_item&.variant
    iframe_image_url = line_item_image_url(order&.line_items&.first, store) if order.line_items.count == 1 && store&.preferences[:store_type] == 'iframe'
    data = {iframe_image_url: iframe_image_url, store_logo_url: store_logo_url, client_address: client_address, sender_name: sender_name, store_name: store&.name, product_slug: store&.products&.first&.slug, order: order_attributes, title: title,  description: description, completed_date: completed_date,
            gift_card_total: gift_card_total, order_total: order_total, ship_address: ship_address_attributes, ship_address_country: ship_address.country.name,
            line_items: line_items, show_discount: order.exchanged_prices[:promo_total].to_f.abs > 0.0, discount: order.display_exchanged(:promo_total),
            show_gifttotal: order.total_applied_gift_card > 0.0, show_inclusive_tax: order.exchanged_prices[:included_tax_total].to_f > 0.0,
            inclusive_tax: inclusive_tax, show_exclusive_tax: order.exchanged_prices[:additional_tax_total].to_f > 0.0,
            exclusive_tax: exclusive_tax, contact_us_blank: config[:contact_us].blank?,
            contact_us: config[:contact_us]&.html_safe, store_url: store_url, order_id: order.id, bill_address: bill_address_attributes,
            bill_address_country: bill_address.country.name, item_total: item_total, ship_total: ship_total, inclusive_tax_label: order.tax_labels[:inclusive],
            exclusive_tax_label: order.tax_labels[:exclusive], decimal_points: order.store.decimal_points, currency_formatter: store.currency_formatter,
            promo_label: (order.labels['promo'] || 'Promo Total'), all_digitals: all_digitals, all_physicals: all_physicals, mix_products: mix_products,
            internal_shipping_name: order&.shipments&.map{|s| s&.shipping_method&.admin_name}&.join(','), product_exist: (total_line_items.map{|l| l.product&.sku}.include?'033115'), language: store&.preferred_default_language || 'en'
    }
    return convert_nil_to_string(data)

  end

  def get_client_address client
    client_address = client&.client_address
    client_address = client_address.present? ? "#{client_address&.address1}, #{client_address&.country&.name}": ""
    return client_address
  end

  def get_store_logo_url store
    image = store&.html_page&.html_layout&.html_components&.find_by_name("Logo")&.html_ui_blocks&.last&.image
    image_url = image&.active_storge_url(image&.attachment)
    return image_url
  end

  def line_item_image_url line_item, store
    image_url = ''
    if line_item&.variant&.images.present?
      img = line_item&.variant&.images&.sort_by{|i|[i.sort_order,i.id]}&.reverse&.first
      image_url = img&.active_storge_url(img&.attachment)
    else
      if line_item.product&.images&.where(thumbnail: true)&.first
        img =  line_item.product&.images&.where(thumbnail: true)&.first
        image_url = img&.active_storge_url(img&.attachment)
      elsif line_item.product&.images&.first
        img =  line_item.product&.images&.first
        image_url = img&.active_storge_url(img&.attachment)
      else
        image_url = store&.active_storge_url(store&.default_thumbnail)
      end
    end
    return image_url
  end

  def convert_nil_to_string(h)
    h.each_with_object({}) { |(k,v),g|
      g[k] = (Hash === v) ?  convert_nil_to_string(v) : v.nil? ? '' : v }
  end

  def str_to_a email_addresses
    email_addresses.split(',').map(&:strip) rescue []
  end

  def send_emails template, data, to_addresses, cc_addresses, bcc_addresses, from_address
    client = Aws::SES::Client.new()
    resp = client.send_templated_email({
                                           source: from_address, # required
                                           destination: { # required
                                                          to_addresses: to_addresses,
                                                          cc_addresses: cc_addresses,
                                                          bcc_addresses: bcc_addresses,
                                           },
                                           template: template, # required
                                           template_data: data.to_json, # required
                                       })
  end
end
