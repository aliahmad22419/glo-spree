class AddMinimumOrderQuantityAndStockSizeToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :minimum_order_quantity, :integer, default: 0
    add_column :spree_products, :pack_size, :integer, default: 1
  end
end
