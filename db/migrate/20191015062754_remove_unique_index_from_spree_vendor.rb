class RemoveUniqueIndexFromSpreeVendor < ActiveRecord::Migration[5.2]
  def change
    remove_index "spree_vendors", name: "index_spree_vendors_on_name"
  end
end
