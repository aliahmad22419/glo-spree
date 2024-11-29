class CreateSpreeCustomizationOptions < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_customization_options do |t|
      t.string :label
      t.string :value
      t.string :sku
      t.float :price
      t.integer :customization_id
      t.timestamps null: false
    end
  end
end
