class AddAttributesToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :manufacturing_lead_time, :integer
    add_column :spree_products, :restricted_area_delivery, :integer
    add_column :spree_products, :delivery_days_to_same_country, :integer
    add_column :spree_products, :delivery_days_to_americas, :integer
    add_column :spree_products, :delivery_days_to_africa, :integer
    add_column :spree_products, :delivery_days_to_australia, :integer
    add_column :spree_products, :delivery_days_to_asia, :integer
    add_column :spree_products, :delivery_days_to_europe, :integer
    add_column :spree_products, :delivery_days_to_restricted_area, :integer

    add_column :spree_customizations, :magento_id, :integer
    add_column :spree_customization_options, :magento_id, :integer
  end
end
