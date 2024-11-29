class AddAttrinuteToShippingMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :visible_to_vendors, :boolean, default: false
  end
end
