class AddRemoveAttributesForGiveX < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_line_item_customizations, :first_name, :string
    remove_column :spree_line_item_customizations, :last_name, :string
    remove_column :spree_line_item_customizations, :email, :string
    add_column :spree_line_items, :receipient_first_name, :string, default: ''
    add_column :spree_line_items, :receipient_last_name, :string, default: ''
    add_column :spree_line_items, :receipient_email, :string, default: ''
  end
end
