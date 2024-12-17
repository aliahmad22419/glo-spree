client = Spree::Client.find(46)

products = client.products.where("shopify_id IS NOT NULL")
products.find_each do |pro|
  pro.variants_including_master.each do |variant|
    opt_val_ids = variant.option_value_ids
    opt_val_ids.each do |ov_id|
      opt_val = Spree::OptionValue.find_by_id(ov_id)
      next unless opt_val.present?
      opt = opt_val.option_type
      property = client.properties.find_by("lower(name) = ?", opt.name.downcase)
      next unless property.present?

      if property.values.split(",").map{|ov|ov.strip.downcase}.include?(opt_val.name.downcase)
        pro.product_properties.find_or_create_by(property_id: property.id, value: opt_val.name)
      end
    end
  end
end

# client.products.sum { |p| p.product_properties.count }
