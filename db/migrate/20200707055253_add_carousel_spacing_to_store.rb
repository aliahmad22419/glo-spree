class AddCarouselSpacingToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :carosel_spacing, :float, default: 52
    add_column :spree_stores, :max_image_width, :integer, default: 600
    add_column :spree_stores, :max_image_height, :integer, default: 600
  end
end
