# p = Spree::Product.last
# p.reload.variants.destroy_all

def import_csv client, file
  results = []
  csv_data = CSV.read("#{file}.csv")
  header, *variants_data = csv_data

  data = variants_data.slice(9862, 13000)
  data.each { |row| results << import_variants(client, row) }
  results
end

def import_variants(client, product)
  result = {}
  puts "=-=-=-=-=-=-=-= Importing #{product[0]} =-=-=-=-=-=-=-="
  return if product[0].blank?
  p = client.products.find_by(name: product[0].strip, shopify_id: product[2]&.strip)
  unless p.present?
    result[:errors] = "Product not found: #{product[0]} - #{product[2]}"
    puts result[:errors]
    return result
  end
  val_ids = []
  client_option_types = client.option_types
  # time = client_option_types.last&.created_at&.beginning_of_day
  # client_option_types = client_option_types.where('created_at >= ?', time)
  client_option_types = client_option_types.sort_by{|op|op.name.downcase}

  client_properties= client.properties
  # time = client_properties.last&.created_at&.beginning_of_day
  # client_properties = client_properties.where('created_at >= ?', time)
  client_properties = client_properties.sort_by{|op|op.name.downcase}

  next_index = client_option_types.count + 5

  var = nil
  is_master = product[4].present? && product[4]&.strip.eql?("Default Title")
  if is_master
    var = p.master
  else
    # var = p.master if p.master.updated_at < DateTime.now.beginning_of_day
    var = p.variants.new unless var.present?
  end

  if is_master
    puts "=-=-=-=-=-=-=-= Importing a master #{product[3]&.strip} =-=-=-=-=-=-=-="
  else
    puts "=-=-=-=-=-=-=-= Importing a variant #{product[3]&.strip} -- #{var.product.variants.count}=-=-=-=-=-=-=-="
  end
  var.price = BigDecimal(product[next_index])
  var.shopify_product_id = p.shopify_id
  var.shopify_id = product[3]&.strip
  var.sku = product[1]&.strip
  # if sku not given use shopify id for variant
  unless var.valid?
    if var.errors.full_messages.include?("SKU has already been taken")
      var.sku = var.shopify_id
    end
  end
  var.sku = var.shopify_id unless var.sku.present?
  var.sku.rjust(6, "0")
  var.save

  client_option_types.each_with_index do |opt, index|
    next unless product[5 + index].present?
    popt = var.product.product_option_types.find_by_option_type_id(opt.id)
    unless popt.present?
      popt = var.product.product_option_types.create(option_type_id: opt.id)
    end

    if product[5 + index].present?
      val_ids += opt.option_values.where('lower(name) IN(?)', product[5+index].split(',').map(&:downcase).map(&:strip)).ids
    end
  end
  var.option_value_ids = val_ids.uniq.compact

  unless var.valid?
    result[:errors] = var.errors.full_messages
    Rails.logger.error("variant:error--#{var.errors.full_messages.join(',')}--shopify-id:#{var.shopify_id}")
    return result
  end
  var.save

  client_properties.each_with_index do |property, index|
    next unless product[5 + index].present?
    propty = var.product.product_properties.find_by(property_id: property.id, value: product[5+index].strip)
    unless propty.present?
      propty = var.product.product_properties.create(property_id: property.id, value: product[5+index].strip)
    end
  end

  next_index = client_option_types.count + 6
  unless product[next_index].to_i.zero?
    sleep 2
    stock = var.reload.stock_items[0]
    stock.update_attribute(:count_on_hand, product[next_index].to_i) rescue stock.try(:count_on_hand)
  end

  result[:id] = var.id
  result[:shopify_id] = var.shopify_id
  result[:shopify_product_id] = var.shopify_product_id

  if var.errors.full_messages.any?
    result[:errors] = var.errors.full_messages
  end
  result
end

# client.products.sum { |p| p.variants_including_master.count }
client = Spree::Client.find(46)
var_import = import_csv(client, "shopify/scripts/v2/files/variants")
