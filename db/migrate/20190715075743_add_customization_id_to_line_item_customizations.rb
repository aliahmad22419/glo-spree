class AddCustomizationIdToLineItemCustomizations < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_item_customizations, :customization_id, :integer
  end
end
