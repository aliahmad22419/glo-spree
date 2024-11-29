class AddClientToSpreeTags < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_tags, :client_id, :integer
    add_index :spree_tags, :client_id
  end
end
