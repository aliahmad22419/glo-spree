class AddHideFromVendorsToSpreeTaxon < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :hide_from_vendors, :boolean, default: false
  end
end
