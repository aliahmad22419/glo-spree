class AddLineItemIdToSpreeShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :line_item_id, :integer
    add_column :spree_shipments, :vendor_id, :integer
  end
end
