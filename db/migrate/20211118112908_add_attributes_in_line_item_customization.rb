class AddAttributesInLineItemCustomization < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_item_customizations, :first_name, :string, default: ''
    add_column :spree_line_item_customizations, :last_name, :string, default: ''
    add_column :spree_line_item_customizations, :email, :string, default: ''
  end
end
