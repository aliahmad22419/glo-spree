class AddCategoryStateToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :category_state, :text
  end
end
