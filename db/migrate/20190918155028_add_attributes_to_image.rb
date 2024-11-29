class AddAttributesToImage < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_assets, :base_image, :boolean, default: false
    add_column :spree_assets, :thumbnail, :boolean, default: false
    add_column :spree_assets, :small_image, :boolean, default: false
  end
end
