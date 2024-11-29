class AddAatributeToVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :banner_image_id, :integer
    add_column :spree_vendors, :image_id, :integer
  end
end
