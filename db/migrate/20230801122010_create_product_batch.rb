class CreateProductBatch < ActiveRecord::Migration[5.2]
  def change
    create_table :product_batches do |t|
      t.string :product_name
      t.integer :product_quantity
      t.jsonb :variants, default: []
      t.integer :status, default: 0
      t.decimal :product_price, precision: 10, scale: 2, default: 0.0
      t.text :option_type_ids, array: true, default: []

      t.references :product, index: true
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
