class AddTrackInventoryColumnToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :track_inventory, :boolean, default: true
  end
end
