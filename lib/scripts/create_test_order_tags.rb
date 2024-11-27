# create tags against existing clients
clients = Spree::Client.all
clients.find_each do |client|
  client_email = client.email || client.users.last.email
  client.order_tags.find_by("Lower(label_name) = ?", :'test order'.to_s) || client.order_tags.create(label_name: :'Test Order'.to_s, intimation_email: client_email)
end

# assign tags to existing orders with store as test_mode
orders = Spree::Order.joins(:store).where(spree_stores: { test_mode: true })
orders.find_each do |order|
  order.create_test_order_tags
end
