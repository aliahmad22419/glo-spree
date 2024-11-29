class AddSlugToTaxonomies < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxonomies, :slug, :string
  end
end
