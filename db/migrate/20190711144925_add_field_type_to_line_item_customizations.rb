class AddFieldTypeToLineItemCustomizations < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_item_customizations, :field_type, :string
  end
end
