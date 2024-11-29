class CreateSpreeCustomization < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_customizations do |t|
      t.string :label
      t.string :field_type
      t.float :price
      t.integer :product_id
      t.boolean :is_required
      t.timestamps null: false
    end
  end
end
