class AddCartTokenToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :cart_token, :string
  end
end
