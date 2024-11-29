class AddShipmentTypeToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :shipment_type, :integer, default: 0
  end
end
