class AddItemsInProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :digital, :boolean, default: false
    add_column :spree_products, :product_type, :string, default: "gift"
    add_column :spree_products, :blocked_dates, :text,  array: true , default: []
  end
end
