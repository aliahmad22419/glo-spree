p = Spree::Product.last
p.reload.variants.destroy_all

def import_csv client, file
  results = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| results << import_variants(client, row) }
  results
end

def import_variants(client, product)
  result = {}
  puts "=-=-=-=-=-=-=-= Importing #{product[0]} =-=-=-=-=-=-=-="
  return if product[0].blank?
  p = client.products.find_by(name: product[0], shopify_id: product[3].strip)
  return "Product not found: #{product[0]} - #{product[3]}" unless p.present?

  val_ids = []
  next_index = client.option_types.size + 5

  var = p.variants.new
  var.price = BigDecimal(product[next_index])
  var.rrp = BigDecimal(product[next_index+1])
  var.shopify_product_id = product[3].strip
  var.shopify_id = product[4].strip
  var.sku = product[4].strip
  var.sku = "#{product[4].strip}-#{p.variants.count}".rjust(6, "0") if var.sku.blank?
  var.sku.rjust(6, "0")

  client.option_types.sort_by{|op|op.name.downcase}.each_with_index do |opt, index|
    popt = p.product_option_types.find_by_option_type_id(opt.id)
    next unless popt.present?

    if product[5+index].present?
      val_ids += popt.option_type.option_values.where('lower(name) IN(?)', product[5+index].split(',').map(&:downcase).map(&:strip)).ids
    end
  end
  var.option_value_ids = val_ids.uniq.compact
  var.save

  sleep 2
  stock = var.stock_items[0]
  stock.update_attribute(:count_on_hand, product[next_index+2].to_i) rescue stock.try(:count_on_hand)

  result[:id] = var.id
  result[:shopify_id] = var.shopify_id
  result[:shopify_product_id] = var.shopify_product_id

  if var.errors.full_messages.any?
    result[:errors] = var.errors.full_messages
  end
  result
end

client = Spree::Client.find(21)
var_import = import_csv(client, "variants_v5")
