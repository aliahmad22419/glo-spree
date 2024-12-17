def import_csv client, file
  new_product_ids = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| new_product_ids << import_product(client, row) }
  new_product_ids
end

def import_product(client, csv)
  begin
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
    p.price = csv[10]
    p.tax_category_id = (client.tax_categories.find_by('lower(name) = ?', csv[11].downcase.strip).try(:id) rescue nil)
    p.on_sale = (csv[12].downcase.strip != "no" rescue false)
    p.sale_price = csv[13].to_f
    p.sale_start_date = (DateTime.parse(csv[14].strip) rescue nil)
    p.sale_end_date = (DateTime.parse(csv[15].strip) rescue nil)
    p.local_area_delivery = csv[16].to_f
    p.wide_area_delivery = csv[17].to_f
    p.delivery_details = csv[18]
    p.manufacturing_lead_time = (csv[19].downcase.split(' day')[0].strip.to_i rescue 0)
    p.shipping_category_id = (client.shipping_categories.find_by('lower(name) = ?', csv[20].downcase.strip).try(:id) rescue nil)
    if p.shipping_category_id.blank?
      p.shipping_category_id = client.shipping_categories.order(:created_at)[0].try(:id)
    end
    if p.shipping_category_id.blank?
      return "no shipping category found for name: #{p.name} "
    end
    p.taxon_ids = (client.taxons.where('lower(name) IN(?)', csv[21].split(',').map(&:downcase).map(&:strip)).ids rescue [])
    p.meta_title = csv[22]
    p.meta_keywords = csv[23]
    p.meta_description = csv[24]
    p.save!

    p.reload
    if csv[25].present?
      csv[25].split(',').map(&:strip).each do |url|
        filename = File.basename(URI.parse(url).path)
        img = Spree::Image.new(viewable_type: "Spree::Variant", attachment_file_name: filename, viewable_id: p.master.id)
        img.attachment.attach(io: open(url), filename: filename)
        img.save
      end
    end

    p.stock_items[0].update(count_on_hand: csv[9].to_i)
    p.reload

    properties = client.properties.sort_by{|op|op.name.downcase}

    properties.each_with_index do |pro, index|
      next unless csv[26+index].present?

      csv[26+index].split(',').map(&:strip).each do |val|
        p.product_properties.create(property_id: pro.id, value: val)
      end
    end

    next_index = properties.size + 26
    p.reload
    if csv[next_index].present?
      csv[next_index].split(',').map(&:strip).each do |opt|
        p.product_option_types.new(option_type_id: client.option_types.find_by('lower(name) = ?', opt.downcase).try(:id)).save
      end
    end
    p.reload.id
  rescue => e
    "error #{csv[0]}"
  end
end

client = Spree::Client.find(22)
imported_ids = import_csv(client, "import_2")

client.reload.products.count
imported_ids.count
