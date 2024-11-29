class AddPreferencesToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :preferences, :text
  end
end
