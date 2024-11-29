class AddDeliveryWithinToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :calculated_days_to_same_country, :integer, default: 0
    add_column :spree_products, :calculated_days_to_restricted_area, :integer, default: 0
    add_column :spree_products, :calculated_days_to_asia, :integer, default: 0
    add_column :spree_products, :calculated_days_to_africa, :integer, default: 0
    add_column :spree_products, :calculated_days_to_americas, :integer, default: 0
    add_column :spree_products, :calculated_days_to_europe, :integer, default: 0
    add_column :spree_products, :calculated_days_to_australia, :integer, default: 0
  end
end
