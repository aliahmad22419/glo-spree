def import_csv client, file
  new_product_ids = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| new_product_ids << import_product(client, row) }
  new_product_ids
end

def import_product(client, csv)
  result = {}
  p = client.products.new
  p.name = csv[0]
  p.vendor_id = (client.vendors.find_by('lower(name) = ?', csv[1].downcase.strip).try(:id) rescue nil)
  p.vendor_sku = csv[2]
  p.store_ids = client.stores.where('lower(name) IN(?)', (csv[3] || '').split(',').map(&:downcase).map(&:strip)).ids
  p.description = csv[4]
  p.long_description = csv[5]
  p.is_gift_card = (csv[6].downcase.strip == "yes" rescue false)
  p.gift_messages = (csv[7].downcase.strip == "yes" rescue false)
  p.stock_status = (csv[8].downcase.strip == "in stock" rescue false)
  p.price = BigDecimal(csv[10])
  p.rrp = csv[11]
  p.minimum_order_quantity = csv[12]
  p.pack_size = csv[13]
  p.tax_category_id = (client.tax_categories.find_by('lower(name) = ?', csv[14].downcase.strip).try(:id) rescue nil)
  p.on_sale = (csv[15].downcase.strip != "no" rescue false)
  p.sale_price = (BigDecimal(csv[16]).negative? ? 0 : BigDecimal(csv[16]))
  p.sale_start_date = (DateTime.parse(csv[17].strip) rescue nil)
  p.sale_end_date = (DateTime.parse(csv[18].strip) rescue nil)
  p.local_area_delivery = BigDecimal(csv[19])
  p.wide_area_delivery = BigDecimal(csv[20])
  p.delivery_details = csv[21]
  p.manufacturing_lead_time = (csv[22].downcase.split(' day')[0].strip.to_i rescue 0)
  p.shipping_category_id = (client.shipping_categories.find_by('lower(name) = ?', csv[23].downcase.strip).try(:id) rescue nil)
  if p.shipping_category_id.blank?
    p.shipping_category_id = client.shipping_categories.order(:created_at)[0].try(:id)
  end
  if p.shipping_category_id.blank?
    return "no shipping category found for name: #{p.name} "
  end
  p.taxon_ids = (client.taxons.where('lower(name) IN(?)', csv[24].split(',').map(&:downcase).map(&:strip)).ids rescue [])
  p.meta_title = csv[25]
  p.meta_keywords = csv[26]
  p.meta_description = csv[27]
  p.save!

  result[:id] = p.reload.id

  if client.supported_currencies.present? && client.supported_currencies[0].present?
    Spree::Currency.create(name: client.supported_currencies[0], vendor_id: p.vendor.id) rescue nil unless p.vendor&.base_currency.present?
  else
    result[:supported_currencies] = "N/A"
  end

  unless p.vendor.present?
    result[:vendor] = "N/A"
  end

  unless p.vendor&.base_currency.present?
    result[:base_currency] = "N/A"
  end

  if csv[28].present?
    csv[28].split(',').map(&:strip).each_with_index do |url, index|
      filename = File.basename(URI.parse(url).path) rescue nil
      next if filename.nil?
      # next if p.images.find_by_attachment_file_name(filename).present?

      img = Spree::Image.new(viewable_type: "Spree::Variant", attachment_file_name: filename, viewable_id: p.master.id)

      opened_url = open(url) rescue nil
      if opened_url.nil?
        result[:"pro_#{p.id}_image_#{index}"] = url
      else
        img.attachment.attach(io: opened_url, filename: filename)
        img.save
      end
    end
  end

  p.stock_items[0].update(count_on_hand: csv[9].to_i)

  properties = client.properties.sort_by{|op|op.name.downcase}

  p.shopify_id = csv[properties.size + 29].strip
  p.save
  p.reload

  properties.each_with_index do |pro, index|
    next unless csv[29+index].present?

    csv[29+index].split(',').map(&:strip).each do |val|
      p.product_properties.create(property_id: pro.id, value: val)
    end
  end

  next_index = properties.size + 28
  p.reload
  if csv[next_index].present?
    csv[next_index].split(',').map(&:strip).each do |opt|
      p.product_option_types.new(option_type_id: client.option_types.find_by('lower(name) = ?', opt.downcase).try(:id)).save
    end
  end
  result
end

client = Spree::Client.find(21)
imported_ids = import_csv(client, "products_v4")
