class AddDefaultTaxZoneToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :default_tax_zone_id, :integer
  end
end
