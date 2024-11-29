class AddGalleryIdInBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :gallery_image_id, :integer
  end
end
