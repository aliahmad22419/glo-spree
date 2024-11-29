class AddTsActionToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :ts_action, :integer, default: 0
  end
end
