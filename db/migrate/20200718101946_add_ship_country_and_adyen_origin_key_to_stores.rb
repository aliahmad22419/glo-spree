class AddShipCountryAndAdyenOriginKeyToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :show_ship_countries, :boolean, default: false
    add_column :spree_stores, :adyen_origin_key, :string, default: ""
  end
end
