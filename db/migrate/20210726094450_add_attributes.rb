class AddAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :product_type, :string
    add_column :spree_line_items, :delivery_mode, :string, default: 'gift'
    add_column :spree_orders, :pick_up_date, :date
    add_column :spree_orders, :pick_up_time, :string, default: ''
    add_column :spree_orders, :delivery_type, :string, default: ''
    add_column :spree_orders, :customer_comment, :text
    add_column :spree_orders, :customer_first_name, :string
    add_column :spree_orders, :customer_last_name, :string
    add_column :spree_stores, :pickup_address_id, :integer
  end
end