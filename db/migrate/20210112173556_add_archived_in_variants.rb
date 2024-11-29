class AddArchivedInVariants < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_variants, :archived, :boolean, default: false
  end
end
