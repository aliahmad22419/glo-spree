#Update conflicted stock_location's id for products variants.
# saas/fix/st-511

Spree::Product.find_each do |product|
  product_stock_items = product.stock_items
  product_stock_location_ids = product_stock_items&.pluck(:stock_location_id).uniq
  vendor_stock_location_ids = product.vendor&.stock_location_ids

  if product_stock_location_ids.length != 1 || ( vendor_stock_location_ids && product_stock_items && product_stock_location_ids != vendor_stock_location_ids )
    puts "conflicted stock_location"
    stock_location_id = vendor_stock_location_ids&.first
    puts "product: #{product.id}, stock_location_ids: #{product_stock_location_ids}, vendor stock location: #{stock_location_id}"
    product_stock_items.update_all(stock_location_id: stock_location_id)
  end
end


#Update conflicted vendors id for products variants.

Spree::Product.find_each do |product|
  vendor_ids = product.variants_including_master.pluck(:vendor_id).uniq
  if vendor_ids.length != 1 || ( vendor_ids && product.vendor_id && vendor_ids.first != product.vendor_id )
    puts "conflicted vendor_id"
    puts "product: #{product.id}, variant's vendor_ids: #{vendor_ids}, product vendor id: #{product.vendor_id}"
    product.variants_including_master.update_all(vendor_id: product.vendor_id)
  end
end
