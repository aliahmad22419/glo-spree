class AddLalamoveInShippingMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :lalamove_enabled, :boolean, default: false
  end
end
