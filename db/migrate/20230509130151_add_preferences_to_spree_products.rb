class AddPreferencesToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :preferences, :text

  end
end
