class AddIndexs < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_vendors, :vacation_start
    add_index :spree_vendors, :vacation_end
    # add_index :spree_products, [:vendor_id, :vendor_id]
    add_index :spree_products, [:vendor_id, :trashbin]
    add_index :spree_products, [:vendor_id, :stock_status]
  end
end
