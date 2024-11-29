class AddPaidPartiallyToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :paid_partially, :boolean, default: false
  end
end
