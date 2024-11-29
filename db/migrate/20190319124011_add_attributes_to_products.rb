class AddAttributesToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :trashbin, :boolean, default: false
    add_column :spree_products, :status, :string, default: "pending"
  end
end
