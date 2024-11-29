class AddLalamoveOrderIdInShipment < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :lalamove_order_id, :string, default: ''
  end
end
