class AddLocalStoreIdsToSpreeVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :local_store_ids, :text, array: true, default: []
  end
end
