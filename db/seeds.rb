# # This file should contain all the record creation needed to seed the database with its default values.
# # The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
# #
# # Examples:
# #
# #   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
# #   Character.create(name: 'Luke', movie: movies.first)

# Spree::Core::Engine.load_seed if defined?(Spree::Core)
# Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
# Spree::Role.find_or_create_by(name: "vendor")
# Spree::Role.find_or_create_by(name: "customer")
# ["Field", "Area", "Drop-down", "Radio Buttons", "Checkbox", "Multiple Select", "File", "Date", "Color"].each do |name|
# 	Spree::Personalization.create(name: name)
# end

# Spree::Store.where(name: "Singapore").first.update_columns(duty: 400, duty_currency: 'SGD')
# Spree::Store.where(name: "Philippines").first.update_columns(duty: 10000, duty_currency: 'PHP')
# Spree::Store.where(name: "Australia").first.update_columns(duty: 1000, duty_currency: 'AUD')
# Spree::Store.where(name: "United Arab Emirates").first.update_columns(duty: 1000, duty_currency: 'AED')
# Spree::Store.where(name: "New Zealand").first.update_columns(duty: 250, duty_currency: 'NZD')
# Spree::Store.where(name: "Rest of World").first.update_columns(duty: 200, duty_currency: 'USD')
# Spree::Store.where(name: "Malaysia").first.update_columns(duty: 500, duty_currency: 'MYR')
# Spree::Store.where(name: "Japan").first.update_columns(duty: 10000, duty_currency: 'JPY')
# Spree::Store.where(name: "China").first.update_columns(duty: 800, duty_currency: 'RMB')
# Spree::Store.where(name: "Indonesia").first.update_columns(duty: 75, duty_currency: 'USD')
# Spree::Store.where(name: "Canada").first.update_columns(duty: 20, duty_currency: 'CAD')
# Spree::Store.where(name: "Great Britain").first.update_columns(duty: 39, duty_currency: 'GBP')

# # Free Shipment
# free_ship_category = Spree::ShippingCategory.create(name: "Free Shipping")
# calculator = Spree::Calculator.create(type: "Spree::Calculator::Shipping::FlatRate",preferences: {:currency=>"USD", :amount=>0.0})
# free_shipment = Spree::ShippingMethod.new(name: "Free Shipping",display_on: "both",code: "FS",calculator: calculator,tax_category_id: nil)
# free_shipment.shipping_categories << free_ship_category
# free_shipment.save!

# store = Spree::Store.where(url: "localhost").first
# page = store.create_html_page(url: '/hero')
# layout = page.create_html_layout(type_of_layout: 'hero', name: 'hero')
# first_compoent = layout.html_components.create(type_of_component: 'logo', name: 'Logo')
# second_compoent = layout.html_components.create(type_of_component: 'announcement_bar', name: 'Announcement Bar')
# second_compoent = layout.html_components.create(type_of_component: 'nav_bar', name: 'Nav Bar')
# second_compoent = layout.html_components.create(type_of_component: 'hero_banner', name: 'Hero Banner')
# second_compoent = layout.html_components.create(type_of_component: 'product_carousel', name: 'Product Carousel')
# second_compoent = layout.html_components.create(type_of_component: 'custom_carousel', name: 'Custom Carousel')
# second_compoent = layout.html_components.create(type_of_component: 'multi_banner', name: 'Multi Banner')
# second_compoent = layout.html_components.create(type_of_component: 'info_text', name: 'Info Text')
# second_compoent = layout.html_components.create(type_of_component: 'newsletter_cta', name: 'Newsletter Cta')
# second_compoent = layout.html_components.create(type_of_component: 'footer', name: 'Footer')
# second_compoent = layout.html_components.create(type_of_component: 'single_banner', name: 'Single Banner')
# first_ui_block = first_compoent.html_ui_blocks.create(title: 'hero1', heading: 'hero1', caption: 'hero1', text_allignment: 'left')
# second_ui_block = first_compoent.html_ui_blocks.create(title: 'hero2', heading: 'hero2', caption: 'hero2', text_allignment: 'right')
# third_ui_block = second_compoent.html_ui_blocks.create(title: 'hero3', heading: 'hero3', caption: 'hero3', text_allignment: 'center')
# first_ui_block.create_html_link(link:"/hero1")
# second_ui_block.create_html_link(link:"/hero2")
# third_ui_block.create_html_link(link:"/hero3")
