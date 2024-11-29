class AddCopyRightsTextToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :copy_rights_text, :string, default: ""
  end
end
