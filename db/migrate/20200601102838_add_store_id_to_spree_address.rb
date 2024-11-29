class AddStoreIdToSpreeAddress < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_addresses, :store_id, :integer
  end
end
