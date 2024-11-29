class CreateSpreeCurrencies < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_currencies do |t|
      t.string :name
      t.float :value
      t.timestamps null: false
    end
  end
end
