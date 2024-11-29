class AddColumnsToTaxon < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :banner_position, :integer
    add_column :spree_taxons, :attachment_id, :integer
    add_column :spree_taxons, :banner_text, :text
  end
end
