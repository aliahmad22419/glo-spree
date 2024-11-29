class AddDeliveryModeInShipment < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :delivery_mode, :string, default: ''
  end
end
