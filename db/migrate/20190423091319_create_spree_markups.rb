class CreateSpreeMarkups < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_markups do |t|
      t.string :name
      t.float :value
      t.integer :currency_id
      t.timestamps null: false
    end
  end
end
