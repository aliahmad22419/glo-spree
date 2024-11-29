class AddFieldsInShippingMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :delivery_mode, :string
    add_column :spree_shipping_methods, :delivery_threshold, :integer
  end
end
