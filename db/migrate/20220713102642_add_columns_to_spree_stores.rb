class AddColumnsToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :min_custom_price, :float, default: 0
    add_column :spree_stores, :max_custom_price, :float, default: 1000
  end
end
