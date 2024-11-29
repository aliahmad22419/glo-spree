class AddShopifyIdToSpreeTaxon < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :shopify_id, :string
  end
end
