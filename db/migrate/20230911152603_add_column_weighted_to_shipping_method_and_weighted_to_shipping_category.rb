class AddColumnWeightedToShippingMethodAndWeightedToShippingCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :is_weighted, :boolean, :default =>  false
    add_column :spree_shipping_categories, :is_weighted, :boolean, :default =>  false
  end
end
