class AddTypeToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :type, :string
    add_column :spree_products, :parent_id, :bigint
    add_column :spree_products, :effective_date, :date
    add_column :spree_products, :daily_stock, :boolean, default: false
    add_reference :spree_products, :product_batch, index: true
  end
end
