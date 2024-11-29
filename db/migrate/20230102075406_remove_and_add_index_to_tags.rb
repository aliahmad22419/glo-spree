class RemoveAndAddIndexToTags < ActiveRecord::Migration[5.2]
  def change
    remove_index :spree_tags, [:name]
    add_index :spree_tags, [:name, :client_id], unique: true
  end
end
