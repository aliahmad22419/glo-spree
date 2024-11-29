class SetDefaultsAndRenameAttributes < ActiveRecord::Migration[5.2]
  def change
    change_column_default(
        :spree_products,
        :manufacturing_lead_time,
        1
    )
    change_column_default(
        :spree_products,
        :restricted_area_delivery,
        0.0
    )
    change_column :spree_products, :restricted_area_delivery, :float, default: 0.0
    
    change_column_default(
        :spree_customization_options,
        :price,
        0.0
    )
    change_column_default(
        :spree_customizations,
        :price,
        0.0
    )
  end
end
