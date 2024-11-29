class AddIndexesToSaleAnalyses < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_orders, :email
    add_index :spree_orders, :user_id
    add_index :spree_vendor_sale_analyses, :number
    add_index :spree_vendor_sale_analyses, :storefront
    add_index :spree_vendor_sale_analyses, :email
    add_index :spree_vendor_sale_analyses, :completed_at
  end
end
