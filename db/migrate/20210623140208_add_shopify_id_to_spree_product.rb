class AddShopifyIdToSpreeProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :shopify_id, :string
  end
end
