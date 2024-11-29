class AddStoreIdToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :store_id, :integer
  end
end
