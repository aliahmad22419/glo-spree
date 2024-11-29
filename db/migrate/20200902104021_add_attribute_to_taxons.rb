class AddAttributeToTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :vendor_id, :integer
    add_column :spree_taxonomies, :vendor_id, :integer
  end
end
