class AddAutoScheduleLalamoveInShippingMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :auto_schedule_lalamove, :boolean, default: false
  end
end
