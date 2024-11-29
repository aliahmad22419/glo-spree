class AddDefaultQuantityToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :default_quantity, :integer, default: 1
    add_column :spree_products, :disable_quantity, :boolean, default: false
  end
end
