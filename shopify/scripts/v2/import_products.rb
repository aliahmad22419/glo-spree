def import_csv client, file
  new_product_ids = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| new_product_ids << import_product(client, row) }
  new_product_ids
end

def import_product(client, csv)
  result = {}
  # for specific vendors only
  vendor_id = client.vendors.find_by('lower(name) = ?', csv[1]&.downcase&.strip).try(:id)
  return { vendor: "#{csv[1].downcase.strip} error:not found" } if vendor_id.blank?
  vendor_names = ["abloom", "beaupharma", "ilia", "grown alchemist", "bybi", "archivist", "andpause vintage", "caes", "capsule studio",
    "kcst", "kings of indigo", "l'envers", "mud jeans", "maium", "riley studio.", "the knotty ones", "atelier labro",
    "adorn", "been", "majavia", "matt & nat", "nortvi", "pala", "totote", "moments of light", "palais", "veja",
  "saye"]
  return { vendor: 'error:not specified' } unless vendor_names.include?(csv[1].downcase.strip)
  
  p = client.products.new
  p.name = csv[0]
  p.vendor_id = vendor_id
  # p.vendor_sku = csv[2]
  # p.store_ids = client.stores.where('lower(name) IN(?)', (csv[2] || '').split(',').map(&:downcase).map(&:strip)).ids
  p.store_ids = client.stores.where('lower(name) IN(?)', "scoon singapore".strip).ids
  p.description = csv[3]
  p.tax_category_id = client.tax_categories.find_by('lower(name) = ?', csv[4]&.downcase&.strip).try(:id)
  p.local_area_delivery = BigDecimal(csv[5])
  p.wide_area_delivery = BigDecimal(csv[6])
  p.manufacturing_lead_time = (csv[7].downcase.split(' day')[0].strip.to_i rescue 0)
  # p.shipping_category_id = client.shipping_categories.find_by('lower(name) = ?', csv[8].downcase.strip).try(:id)
  p.shipping_category_id = client.shipping_categories.find_by('lower(name) = ?', 'scoon').try(:id)
  if p.shipping_category_id.blank?
    p.shipping_category_id = client.shipping_categories.order(:created_at)[0].try(:id)
  end
  if p.shipping_category_id.blank?
    return "no shipping category found for name: #{p.name} "
  end
  p.meta_title = csv[9]
  p.meta_keywords = csv[10]
  p.meta_description = csv[11]
  # images at column 12
  p.shopify_id = csv[13].strip
  p.vendor_sku = p.shopify_id
  # update price from master variant
  p.price = 0
  p.save
  result[:id] = p.reload.id

  if csv[12].present?
    csv[12].split(',').map(&:strip).each_with_index do |url, index|
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
  # p.stock_status = (csv[8].downcase.strip == "in stock" rescue false)

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
  result
end

# scn@techsembly.com / testing!23
# user = Spree::User.where(email: 'scn@techsembly.com')
# client = user[0].client
client = Spree::Client.find(46).products.count
imported_ids = import_csv(client, "shopify/scripts/v2/files/scoon_products")
