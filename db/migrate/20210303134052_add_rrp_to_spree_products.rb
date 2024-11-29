class AddRrpToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :rrp, :float
  end
end
