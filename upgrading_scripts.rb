# Spree 4.3 scripts

# Copy data from the old `favicon` to the new `favicon_image`
# as spree added its own `favicon_image `
# after running this script please remove this line `remove_method :favicon` from store_decorator.rb
# and also remove favicon attachment relationship from store_decorator.rb
# SKIP THIS STEP FOR SPREE 4.6 OR LATER
# Spree::Store.find_each do |record|
#   if record.favicon&.attached?
#     record.favicon_image.attach(record.favicon.blob)
#     puts record.id
#     record.save!
#   end
# end

# Spree 4.4 scripts


# Spree 4.6
# price got nil as Spree::Config[:default_currency] replaced by Spree::Store.default.default_currency
# Move Spree::Store.default.default_currency to Spree.Config[:default_currency]
# Spree::Store.default.update default_currency: "USD"

# script to change status of products
products = Spree::Product.all
products.each do |product|
	product.update_column(:status, product.status == 'approved' ? 'active' : 'draft') unless ['active', 'draft'].include? product.status
end

# make spree giftcard payment work in spree 4.6
Spree::Config.allow_gift_card_partial_payments = true