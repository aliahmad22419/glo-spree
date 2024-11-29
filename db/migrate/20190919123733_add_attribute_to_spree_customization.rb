class AddAttributeToSpreeCustomization < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_customizations, :max_characters, :integer
  end
end
