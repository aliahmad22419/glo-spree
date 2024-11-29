class AddEnableProductInfoToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :enable_product_info, :boolean, default: false
  end
end
