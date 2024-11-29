class AddBrandNameSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :brand_name, :string
  end
end
