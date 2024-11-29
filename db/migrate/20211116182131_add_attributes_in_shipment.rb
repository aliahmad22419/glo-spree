class AddAttributesInShipment < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :delivery_type, :string, default: ''
    add_column :spree_shipments, :delivery_pickup_date, :date
    add_column :spree_shipments, :delivery_pickup_time, :string, default: ''
  end
end
