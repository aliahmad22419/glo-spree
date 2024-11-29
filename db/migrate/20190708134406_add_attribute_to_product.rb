class AddAttributeToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :local_area_delivery, :decimal, precision: 8, scale: 2
    add_column :spree_products, :wide_area_delivery, :decimal, precision: 8, scale: 2
  end
end
