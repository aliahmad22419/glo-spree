class AddStoreIdsInUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :allow_store_ids, :text, array: true, default: []
  end
end
