class AddGivexSecondaryUrlToStores < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_stores, :givex_secondary_url, :string
  end
end
