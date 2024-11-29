class AddDecimalPointsToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :decimal_points, :integer, default: 2
  end
end
