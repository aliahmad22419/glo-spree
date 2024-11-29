class AddPreferenceToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :preferences, :text
  end
end
