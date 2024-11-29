class AddHidePriceToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :hide_price, :boolean, default: false
  end
end
