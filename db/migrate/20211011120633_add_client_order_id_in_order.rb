class AddClientOrderIdInOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :client_order_id, :integer, default: 0
  end
end
