class CreateLineItemCustomizations < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_line_item_customizations do |t|
      t.string :name
      t.float :price
      t.string :title
      t.string :value
      t.integer :customization_option_id
      t.references :line_item

      t.timestamps
    end
  end
end
