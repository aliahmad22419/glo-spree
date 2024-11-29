class AddStoreIdToSpreeSitemap < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_sitemaps, :store_id, :integer
  end
end
