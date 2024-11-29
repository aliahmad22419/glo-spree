class AddRecentProductsToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :recent_product_ids, :text,  array: true , default: []
  end
end
