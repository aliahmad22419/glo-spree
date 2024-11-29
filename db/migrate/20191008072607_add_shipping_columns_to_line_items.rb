class AddShippingColumnsToLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :local_area_delivery, :float, default: 0.0
    add_column :spree_line_items, :wide_area_delivery, :float, default: 0.0
    add_column :spree_line_items, :shipping_category, :string, default: ""
  end
end
