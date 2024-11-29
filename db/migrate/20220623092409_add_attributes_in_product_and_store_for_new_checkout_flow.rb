class AddAttributesInProductAndStoreForNewCheckoutFlow < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :checkout_flow_v2, :boolean, default: false
    add_column :spree_products, :recipient_details_on_detail_page, :boolean, default: false
    add_column :spree_line_items, :sender_name, :string, default: ''
  end
end
