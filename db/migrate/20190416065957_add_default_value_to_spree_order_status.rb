class AddDefaultValueToSpreeOrderStatus < ActiveRecord::Migration[5.2]
  def change
    change_column_default :spree_orders, :status, "pending"
  end
end
