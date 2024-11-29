class AddZoneBasedStoresToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :zone_based_stores, :boolean, default: false
  end
end
