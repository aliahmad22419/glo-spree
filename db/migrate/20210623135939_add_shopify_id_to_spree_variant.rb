class AddShopifyIdToSpreeVariant < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_variants, :shopify_id, :string
    add_column :spree_variants, :shopify_product_id, :string
  end
end
