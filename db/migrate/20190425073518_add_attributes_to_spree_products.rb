class AddAttributesToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :long_description, :text
    add_column :spree_products, :gift_messages, :boolean, default: false
    add_column :spree_products, :vendor_sku, :string, default: ""
  end
end
