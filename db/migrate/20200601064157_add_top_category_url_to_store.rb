class AddTopCategoryUrlToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :top_category_url_to_product_listing, :boolean, default: false
  end
end
