class AddLalamoveTagsIdInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :lalamove_pickup_order_tag_id, :integer
    add_column :spree_stores, :lalamove_complete_order_tag_id, :integer
  end
end
