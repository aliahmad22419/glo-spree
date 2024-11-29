class AddTestModeColumnToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :test_mode, :boolean, default: true
  end
end
