class AddHideCartToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :disable_cart, :boolean, default: false
  end
end
