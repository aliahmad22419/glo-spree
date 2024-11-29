class AddMigrationShipToLabel < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :ship_to_label, :string, default: ""
  end
end
