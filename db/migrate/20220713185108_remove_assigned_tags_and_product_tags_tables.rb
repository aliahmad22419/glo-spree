class RemoveAssignedTagsAndProductTagsTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :spree_assigned_tags
    drop_table :spree_product_tags
  end
end
