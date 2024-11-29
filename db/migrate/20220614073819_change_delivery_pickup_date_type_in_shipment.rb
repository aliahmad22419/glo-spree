class ChangeDeliveryPickupDateTypeInShipment < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :delivery_pickup_date_zone, :string
  end
end
