class CreateOrderTagOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_order_tags_orders do |t|
      t.references :order
      t.references :order_tag
      t.timestamps
    end
  end
end
