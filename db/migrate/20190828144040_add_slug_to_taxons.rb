class AddSlugToTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :slug, :string
  end
end
