class AddSalePriceToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :sale_price, :float, default: 0.0
  end
end
