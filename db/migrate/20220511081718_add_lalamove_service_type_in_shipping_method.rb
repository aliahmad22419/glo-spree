class AddLalamoveServiceTypeInShippingMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :lalamove_service_type, :string, default: ''
  end
end
