class AddStatusToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :status, :string
  end
end
