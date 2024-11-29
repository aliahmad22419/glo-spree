class AddNotesToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :notes, :text
  end
end
