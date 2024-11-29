class AddSortOrderToSpreeImages < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_assets, :sort_order, :integer, default: 1
  end
end
