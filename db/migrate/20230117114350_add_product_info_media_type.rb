class AddProductInfoMediaType < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_info_products, :media_type, :integer, default: 0
    rename_column :spree_info_products, :video_url, :media_url
  end
end
