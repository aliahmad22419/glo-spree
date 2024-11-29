class GalleryTimestamp < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :spree_galleries, default: -> { 'now()' }, null: false
  end
end
