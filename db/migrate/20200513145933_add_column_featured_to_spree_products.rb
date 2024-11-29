class AddColumnFeaturedToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :featured, :boolean
  end
end
