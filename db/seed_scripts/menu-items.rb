MenuItem.create([
    {name: "Dashboard", url: "/sub-client-landing", visible: false, img_url: 'assets/img/home-new.svg', menu_permission_roles: ['sub_client'], namespace: true, priority: 1, permissible: true},
    {name: "Home", url: "/reporting", visible: true, img_url: 'assets/img/home-new.svg', menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 2, permissible: true},
    {name: "Orders", url: "/orders", visible: true , img_url: 'assets/img/cube.svg', menu_permission_roles:['client', 'sub_client', 'vendor'], namespace: true, priority: 3, permissible: true},
    {name: "Products", url: "#", visible: true, img_url: 'assets/img/tag-new.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 4, permissible: true},
    {name: "TS Gifts Curate", url: "/gift-cards", visible: true, img_url: 'assets/img/gift-new.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 5, permissible: true},
    {name: "GiveX Cards", url: "/givex-cards-list", visible: true, img_url: 'assets/img/gift-new.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 6, permissible: true},
    {name: "Conversations", url: "/questions/all-questions", visible: true, img_url: 'assets/img/conv.svg', menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 7, permissible: true},
    {name: "Users", url: "/users", visible: true, img_url: 'assets/img/user.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 8, permissible: true},
    {name: "Vendors", url: "/vendors", visible: true, img_url: 'assets/img/cart-white.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 9, permissible: true},
    {name: "Stores", url: "/stores", visible: true, img_url: 'assets/img/clipboard.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 10, permissible: true},
    {name: "Categories", url: "/create-category", visible: true, img_url: 'assets/img/layers-white.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 11, permissible: true},
    {name: "Gallery", url: "/gallery", visible: true, img_url: 'assets/img/sidebar.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 12, permissible: true},
    {name: "Notifications", url: "/information-instructions/notifications", visible: true, img_url: 'assets/img/notify-waves.svg', menu_permission_roles: ['vendor'], namespace: true, priority: 13, permissible: true},
    {name: "Requests", url: "/follow-requests", visible: false, img_url: 'assets/img/life-buoy.svg', menu_permission_roles: ['vendor'], namespace: true, priority: 14, permissible: true},
    {name: "Settings", url: "/settings/main", visible: true, img_url: 'assets/img/settings-light.svg', menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 15, permissible: true},
    {name: "Products", url: "/products/list-product", visible: true, img_url: 'assets/img/tag-new.svg', menu_permission_roles:['vendor'], namespace: true, priority: 4, permissible: true},
    {name: 'Reporting (Including PII)', url: '/reports/including-ppi', visible: true, img_url: 'assets/img/layers-white.svg', parent_id: nil, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2.1, permissible: true},
    {name: 'Reporting (Excluding PII)', url: '/reports/excluding-ppi', visible: true, img_url: 'assets/img/layers-white.svg', parent_id: nil, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2.2, permissible: true},
    {name: "Download Reports", url: "/dashboard", visible: false, img_url: 'assets/img/tag-new.svg', parent_id: nil, menu_permission_roles: ['client','sub_client','vendor'], namespace: true, priority: 2.3, permissible: false},
    {name: "Corporate Order", url: "/bulk-orders", visible: true, img_url: 'assets/img/cube.svg', parent_id: nil, menu_permission_roles: ['client','sub_client'], namespace: true, priority: 14, permissible: true}
])

bulk_orders = MenuItem.find_by(name: "Corporate Order", url: "/bulk-orders")
if bulk_orders.present?
    MenuItem.create([
        {name: 'Create Corporate Order', url: '/bulk-order/create-bulk', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: bulk_orders.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 14.1, permissible: false},
        {name: 'Corporate Order Details', url: '/bulk-orders/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: bulk_orders.id, menu_permission_roles: ['client','sub_client'], namespace: true, priority: 14.2, permissible: false},
    ])
end

MenuItem.create([
    {name: "Linked Inventory", url: "#", visible: true, img_url: 'assets/img/home-new.svg', menu_permission_roles: ['vendor'], namespace: true, priority: 54, permissible: false},
])

linked_inventory = MenuItem.find_by(name: "Linked Inventory", url: "#")
if linked_inventory.present?
    MenuItem.create([
        {name: 'Inventory List', url: '/inventory-list', visible: true, img_url: 'assets/img/tag-new.svg', parent_id: linked_inventory.id, menu_permission_roles: ['vendor'], namespace: true, priority: 54.1, permissible: false},
        {name: 'Create Inventory', url: '/create-inventory', visible: true, img_url: 'assets/img/tag-new.svg', parent_id: linked_inventory.id, menu_permission_roles: ['vendor'], namespace: true, priority: 54.2, permissible: false},
        {name: 'Edit Inventory', url: '/inventories/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: linked_inventory.id, menu_permission_roles: ['vendor'], namespace: true, priority: 54.3, permissible: false}
    ])
end

orders_menu_item = MenuItem.find_by(name: 'Orders', url: '/orders')
if orders_menu_item.present?
    MenuItem.create([
        {name: 'Order Detail', url: '/orders/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: orders_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: false},
        {name: 'New Return Authorization', url: '/orders/:id/return-authorizations/new', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: orders_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2, permissible: false}
    ])
end

# Should be child of products_menu_item, here due to mixed permissible
edit_stock = MenuItem.create([{
    name: 'Edit Stock Product',
    url: '/stock-product/:id',
    visible: false,
    img_url: 'assets/img/tag-new.svg',
    parent_id: nil,
    menu_permission_roles: ['client', 'sub_client', 'vendor'],
    namespace: true,
    priority: 5,
    permissible: false
}])

products_menu_item = MenuItem.find_by(name: 'Products', url: '#')
if products_menu_item.present?
    MenuItem.create([
        {name: "Product Approval", url: "/products/approval", visible: true, img_url: 'assets/img/tag-new.svg', parent_id: products_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: true},
        {name: "Create Product", url: "/create-product", visible: true, img_url: 'assets/img/tag-new.svg', parent_id: products_menu_item.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 2, permissible: true},
        {name: "Product Stocks", url: "/inventory/product-stocks", visible: true, img_url: 'assets/img/tag-new.svg', parent_id: products_menu_item.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 3, permissible: true},
        {name: "Import Stocks", url: "/inventory/import-stocks", visible: true, img_url: 'assets/img/tag-new.svg', parent_id: products_menu_item.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 4, permissible: true},
        {name: 'Preview Product', url: '/product/:id/preview', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: products_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 7, permissible: true},
        {name: 'Product Trashbin', url: '/product-trashbin', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: products_menu_item.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 6, permissible: true}
    ])
end

product_approval = MenuItem.find_by(name: "Product Approval", url: "/products/approval")
if products_menu_item.present?
    MenuItem.create([
        {name: "Edit Product", url: "/product/:id", visible: false, img_url: 'assets/img/tag-new.svg', parent_id: product_approval.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: false}
   ])
end

product_stocks = MenuItem.find_by(name: "Product Stocks", url: "/inventory/product-stocks")
if products_menu_item.present?
    MenuItem.create([
        {name: "Edit Products Stock", url: "/products/:id", visible: false, img_url: 'assets/img/tag-new.svg', parent_id: product_stocks.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: false}
   ])
end

vendors_menu_item = MenuItem.find_by(name: 'Vendors', url: '/vendors')
if vendors_menu_item.present?
    MenuItem.create([
        {name: "Create Vendor", url: "/create-vendor", visible: false, img_url: 'assets/img/tag-new.svg', parent_id: vendors_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: false},
        {name: "Edit Vendor", url: "/edit-vendor/:id", visible: false, img_url: 'assets/img/tag-new.svg', parent_id: vendors_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2, permissible: false},
        {name: "Vendor Invitation", url: "/vendor-invitation", visible: false, img_url: 'assets/img/cart-white.svg', parent_id: vendors_menu_item.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 9, permissible: false}
    ])
end

ts_gift_curate = MenuItem.find_by(name: 'TS Gifts Curate', url: '/gift-cards')
if ts_gift_curate.present?
    MenuItem.create([
        {name: 'TS Gift Cards', url: '/gift-cards-listing', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "5.01", permissible: true},
        {name: 'Create Gift Card', url: '/create-gift-cards', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority:  "5", permissible: true},
        {name: 'TS Campaigns', url: '/campaigns', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "5.02", permissible: true},
        {name: 'TS Stores', url: '/tsstores', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "5.03", permissible: true},
        {name: 'TS Front Desk Users', url: '/tsusers', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "5.04", permissible: true},
        {name: "Active Physical Card", url: "/active-physical-cards", visible: false, parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: true},
        {name: "Transaction Reason", url: "/transaction-reason", img_url: 'assets/img/tag-new.svg', visible: false, parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "5.05", permissible: true},
        {name: "Client Setting", url: "/ts-setting", visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_gift_curate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "5.06", permissible: true}
    ])
end

gift_cards = MenuItem.find_by(name: 'TS Gift Cards', url: '/gift-cards-listing')
if gift_cards.present?
    MenuItem.create([
        {name: 'Edit Gift Card Details', url: '/gift-cards/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: gift_cards.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 6, permissible: false}
   ])
end

campaigns = MenuItem.find_by(name: 'TS Campaigns', url: '/campaigns')
if campaigns.present?
    MenuItem.create([
        {name: 'Create Campaigns', url: '/create-campaigns', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: campaigns.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 7, permissible: false},
        {name: 'Edit Campaigns', url: '/campaigns/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: campaigns.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 8, permissible: false}
    ])
end

stores = MenuItem.find_by(name: 'TS Stores', url: '/tsstores')
if stores.present?
    MenuItem.create([
        {name: 'Create TS Store', url: '/create-tsstores', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 9, permissible: false},
        {name: 'Edit TS Store', url: '/tsstores/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 10, permissible: false},
        {name: "TS Store Department List", url: "/tsstores/:id/department-list", visible: false, parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false},
        {name: "TS Store Create Department", url: "/tsstores/:id/create-department", visible: false, parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false},
        {name: "TS Store Update Department", url: "/tsstores/:id/department/:id", visible: false, parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false},
        {name: "TS Store Experience List", url: "/tsstores/:id/experience-list", visible: false, parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false},
        {name: "TS Store Create Experience", url: "/tsstores/:id/create-experience", visible: false, parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false},
        {name: "TS Store Update Experience", url: "/tsstores/:id/experience/:id", visible: false, parent_id: stores.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false}
    ])
end

ts_users = MenuItem.find_by(name: 'TS Front Desk Users', url: '/tsusers')
if ts_users.present?
    MenuItem.create([
        {name: 'Create TS User', url: '/create-tsusers', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_users.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 11, permissible: false},
        {name: 'Edit TS User', url: '/tsusers/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: ts_users.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 12, permissible: false}
    ])
end

transaction_reason_list = MenuItem.find_by(name: "Transaction Reason", url: "/transaction-reason")
if transaction_reason_list.present?
    MenuItem.create([
        {name: "Update Transaction Reason", url: "/transaction-reason/:id", visible: false, parent_id: transaction_reason_list.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false},
        {name: "Create Transaction Reason", url: "/create-transaction-reasons", visible: false, parent_id: transaction_reason_list.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, permissible: false}
    ])
end

givex_cards_menu = MenuItem.find_by(name: 'GiveX Cards', url: '/givex-cards-list')
if givex_cards_menu.present?
    MenuItem.create([
        {name: 'Create GiveX Card', url: '/create-givex-card', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: givex_cards_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: false},
        {name: 'GiveX Card Details', url: '/givex-cards/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: givex_cards_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2, permissible: false},
        {name: 'Active GiveX Card', url: '/active-givex-card', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: givex_cards_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 3, permissible: false},
        {name: 'Activate GiveX Card', url: '/givex_activate_card', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: givex_cards_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 4, permissible: false},
        {name: 'GiveX Card List', url: '/givex-cards-list', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: givex_cards_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 5, permissible: false}
        ])
end

conversations_menu = MenuItem.find_by(name: 'Conversations', url: '/questions/all-questions')
if conversations_menu.present?
    MenuItem.create([
        {name: 'Open Questions', url: '/questions/open-questions', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: conversations_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 1, permissible: false},
        {name: 'Archived Questions', url: '/questions/archived-questions', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: conversations_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 2, permissible: false},
        {name: 'Question Details', url: '/questions/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: conversations_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 3, permissible: false}
    ])
end

users_menu = MenuItem.find_by(name: 'Users', url: '/users')
if users_menu.present?
    MenuItem.create([
        {name: 'Create User', url: '/users/create-user', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: users_menu.id, menu_permission_roles: ['client'], namespace: true, priority: 1, permissible: false},
        {name: 'Edit User', url: '/users/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: users_menu.id, menu_permission_roles: ['client'], namespace: true, priority: 2, permissible: false}
    ])
end

stores_parent_menu = MenuItem.find_by(name: 'Stores', url: '/stores')
if stores_parent_menu.present?
    MenuItem.create([
        {name: 'Create Store', url: '/create-store', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: true},
        {name: 'Edit Store', url: '/edit-store/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2, permissible: false},
        {name: 'Ses Emails', url: '/stores/:id/ses-emails', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 3, permissible: false},
        {name: 'Store Versions', url: '/stores/:id/versions', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 4, permissible: false},
        {name: 'Page Builder', url: '/customize-store/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: false, priority: 5, permissible: false},
        {name: 'Create Route', url: '/create-route', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 50, permissible: false},
        {name: 'Edit Route', url: '/edit-route/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: stores_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 51, permissible: false}
    ])
end

gallery_parent_menu = MenuItem.find_by(name: 'Gallery', url: '/gallery')
if gallery_parent_menu.present?
    MenuItem.create([
        {name: 'Upload Image', url: '/gallery/create-gallery', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: gallery_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 1, permissible: false},
        {name: 'Edit Image', url: '/gallery/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: gallery_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2, permissible: false}
    ])
end

settings_parent_menu = MenuItem.find_by(name: 'Settings', url: '/settings/main')
if settings_parent_menu.present?
    MenuItem.create([
        {name: 'Tax Category', url: '/tax-category/list-tax-category', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.01", permissible: true},
        {name: 'Tax Rate', url: '/tax-rate/list-tax-rate', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.02", permissible: true},
        {name: 'Exchange Rates', url: '/exchange-rates', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.03", permissible: true},
        {name: 'Supported Currencies', url: '/settings/set-supported-currencies', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.04", permissible: true},
        {name: 'Shipping Category', url: '/shipping-category/list-shipping-category', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.05", permissible: true},
        {name: 'Shipping Methods', url: '/shipping-method/list-shipping-method', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: "15.06", permissible: true},
        {name: 'Payment Methods', url: '/payment-method/list-payment-method', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.07", permissible: true},
        {name: 'Tax Zone', url: '/zone/list-zone', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.08", permissible: true},
        {name: 'Vendors Dashboard', url: '/pages', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.09", permissible: true},
        {name: 'Static Pages', url: '/static-pages', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.10", permissible: true},
        {name: 'Properties', url: '/properties', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.11", permissible: true},
        {name: 'Option Types', url: '/option-types', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.12", permissible: true},
        {name: 'Set Base Currency', url: '/set-base-currency', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.13", permissible: true},
        {name: 'Order Tags', url: '/order-tags', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.14", permissible: true},
        {name: 'Product Tags', url: '/product-tags', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.15", permissible: true},
        {name: 'Account Information', url: '/settings/profile', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['vendor'], namespace: true, priority: "15.16", permissible: true},
        {name: 'Master Vendor Profile', url: '/master-vendor-profile', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.17", permissible: true},
        {name: 'Promotions', url: '/promotions/list-promotions', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.18", permissible: true},
        {name: 'Promotion Categories', url: '/promotion-categories/list-promotion-categories', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.19", permissible: true},
        {name: 'Schedule Reports', url: '/schedule-reports/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: "15.20", permissible: true},
        {name: 'Ses Email Templates', url: '/ses-email-templates/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: "15.21", permissible: true},
        {name: 'Account Information', url: '/account', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.16", permissible: true},
        {name: 'Send Notifications', url: '/send-notifications',  parent_id: settings_parent_menu.id, visible: false, img_url: 'assets/img/tag-new.svg', menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 48, permissible: false},
        {name: 'Reimbursements', url: '/settings/reimbursements', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 52, permissible: false},        
        {name: 'Currency', url: '/settings/currencies', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['vendor'], namespace: true, priority: 53, permissible: false},
        {name: 'AWS Files', url: '/aws/list-aws-file', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 54, permissible: true}
    ])
end

tax_category = MenuItem.find_by(name: 'Tax Category', url: '/tax-category/list-tax-category')
if tax_category.present?
    MenuItem.create([
        {name: 'Create Tax Category', url: '/tax-category/create-tax-category', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: tax_category.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 2, permissible: false},
        {name: 'Edit Tax Category', url: '/tax-category/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: tax_category.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 3, permissible: false}
    ])
end

tax_rate = MenuItem.find_by(name: 'Tax Rate', url: '/tax-rate/list-tax-rate')
if tax_rate.present?
    MenuItem.create([
        {name: 'Create Tax Rate', url: '/tax-rate/create-tax-rate', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: tax_rate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 5, permissible: false},
        {name: 'Edit Tax Rate', url: '/tax-rate/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: tax_rate.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 6, permissible: false}   
    ])
end

shipping_category = MenuItem.find_by(name: 'Shipping Category', url: '/shipping-category/list-shipping-category')
if shipping_category.present?
    MenuItem.create([
        {name: 'Create Shipping Category', url: '/shipping-category/create-shipping-category', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: shipping_category.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 10, permissible: false},
        {name: 'Edit Shipping Category', url: '/shipping-category/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: shipping_category.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 11, permissible: false}
    ])
end

shipping_methods = MenuItem.find_by(name: 'Shipping Methods', url: '/shipping-method/list-shipping-method')
if shipping_methods.present?
    MenuItem.create([
        {name: 'Create Shipping Method', url: '/shipping-method/create-shipping-method', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: shipping_methods.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 13, permissible: false},
        {name: 'Edit Shipping Method', url: '/shipping-method/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: shipping_methods.id, menu_permission_roles: ['client', 'sub_client', 'vendor'], namespace: true, priority: 14, permissible: false}
    ])
end

payment_methods = MenuItem.find_by(name: 'Payment Methods', url: '/payment-method/list-payment-method')
if payment_methods.present?
    MenuItem.create([
        {name: 'Create Payment Method', url: '/payment-method/create-payment-method', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: payment_methods.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 16, permissible: false},
        {name: 'Edit Payment Method', url: '/payment-method/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: payment_methods.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 17, permissible: false}
    ])
end

zone = MenuItem.find_by(name: 'Zone', url: '/zone/list-zone')
if zone.present?
    MenuItem.create([
        {name: 'Create Zone', url: '/zone/create-zone', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: zone.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 19, permissible: false},
        {name: 'Edit Zone', url: '/zone/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: zone.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 20, permissible: false}
    ])
end

pages = MenuItem.find_by(name: 'Vendors Dashboard', url: '/pages')
if pages.present?
    MenuItem.create([
        {name: 'Create Page', url: '/create-page', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: pages.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 22, permissible: false},
        {name: 'Edit Page', url: '/edit-page/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: pages.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 23, permissible: false}
    ])
end

static_pages = MenuItem.find_by(name: 'Static Pages', url: '/static-pages')
if static_pages.present?
    MenuItem.create([
        {name: 'Create Static Page', url: '/create-static-page', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: static_pages.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 25, permissible: false},
        {name: 'Edit Static Page', url: '/edit-static-page/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: static_pages.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 26, permissible: false}
    ])
end

properties = MenuItem.find_by(name: 'Properties', url: '/properties')
if properties.present?
    MenuItem.create([
        {name: 'Create Properties', url: '/create-properties', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: properties.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 28, permissible: false},
        {name: 'Edit Properties', url: '/properties/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: properties.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 29, permissible: false}
    ])
end

option_types = MenuItem.find_by(name: 'Option Types', url: '/option-types')
if option_types.present?
    MenuItem.create([
        {name: 'Create Option Types', url: '/create-option-types', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: option_types.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 31, permissible: false},
        {name: 'Edit Option Types', url: '/option-types/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: option_types.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 32, permissible: false}
    ])
end

order_tags = MenuItem.find_by(name: 'Order Tags', url: '/order-tags')
if order_tags.present?
    MenuItem.create([
        {name: 'Edit Order Tag', url: '/order-tags/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: order_tags.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 35, permissible: false},
        {name: 'Create Order Tag', url: '/create-order-tag', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: order_tags.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 36, permissible: false}
    ])
end

product_tags = MenuItem.find_by(name: 'Product Tags', url: '/product-tags')
if order_tags.present?
    MenuItem.create([
        {name: 'Edit Product Tag', url: '/product-tags/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: product_tags.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 38, permissible: false},
        {name: 'Create Product Tag', url: '/create-product-tag', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: product_tags.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 39, permissible: false}
    ])
end

promotions = MenuItem.find_by(name: 'Promotions', url: '/promotions/list-promotions')
if promotions.present?
    MenuItem.create([
        {name: 'Create Promotion', url: '/promotion/create-promotion', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: promotions.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 43, permissible: false},
        {name: 'Edit Promotion', url: '/promotion/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: promotions.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 44, permissible: false}
    ])
end

promotion_categories = MenuItem.find_by(name: 'Promotion Categories', url: '/promotion-categories/list-promotion-categories')
if promotion_categories.present?
    MenuItem.create([
        {name: 'Create Promotion Category', url: '/promotion-category/create-promotion-category', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: promotion_categories.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 46, permissible: false},
        {name: 'Edit Promotion Category', url: '/promotion-category/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: promotion_categories.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 47, permissible: false}
    ])
end

# Assign all permissions to all sub users
sub_client_users = Spree::User.joins(:spree_roles).where(:spree_roles => {:name => 'sub_client' }).uniq

sub_client_users.each do |user|
  menu_items = MenuItem.permissible.where('menu_permission_roles @> ARRAY[?]::text[]', ['sub_client'])
    menu_items.each do |mi|
        user.menu_item_users.create(menu_item: mi, visible: mi.visible, permissible: mi.permissible)
    end
end

settings_parent_menu = MenuItem.find_by(name: 'Settings', url: '/settings/main')
MenuItem.create([
    {name: 'Invite for Whitelisting', url: '/whitelist-email/list-whitelist-email', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: settings_parent_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.22", permissible: true},
])

whitelisted_emails = MenuItem.find_by(name: 'Invite for Whitelisting', url: '/whitelist-email/list-whitelist-email')
MenuItem.create([
    {name: 'Whitelist New Email', url: '/whitelist-email/create-whitelist-email', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: whitelisted_emails.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.23", permissible: false},
    {name: 'Whitelist New Domain', url: '/whitelist-email/create-whitelist-domain', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: whitelisted_emails.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.24", permissible: false},
    {name: 'Whitelist Show Domain', url: '/whitelist-email/show-whitelist-domain/:id', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: whitelisted_emails.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: "15.25", permissible: false}
])

aws_files_menu = MenuItem.find_by(name: 'AWS Files', url: '/aws/list-aws-file')
if aws_files_menu.present?
    MenuItem.create([
        {name: 'Create AWS Files', url: '/aws/create-aws-file', visible: false, img_url: 'assets/img/tag-new.svg', parent_id: aws_files_menu.id, menu_permission_roles: ['client', 'sub_client'], namespace: true, priority: 54.1, permissible: false}
    ])
end