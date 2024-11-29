class AddAttributeToCustomization < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_customizations, :order, :integer
  end
end
