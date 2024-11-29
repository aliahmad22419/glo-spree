class AddAttributeToSpreeCustomizationOptions < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_customization_options, :max_characters, :integer
  end
end
