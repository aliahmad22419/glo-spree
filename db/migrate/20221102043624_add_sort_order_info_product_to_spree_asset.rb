class AddSortOrderInfoProductToSpreeAsset < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_assets, :sort_order_info_product, :integer, default: 1
  end
end
