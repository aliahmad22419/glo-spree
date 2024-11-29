class AddStockStatusToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :stock_status, :boolean, default: true
  end
end
