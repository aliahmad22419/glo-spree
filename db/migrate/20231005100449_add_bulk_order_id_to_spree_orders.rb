class AddBulkOrderIdToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :bulk_order_id, :integer, default: nil
  end
end
