class CreateSpreePages < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_pages do |t|
      t.string :title
      t.integer :order
      t.string :status
      t.string :heading
      t.text :content
      t.timestamps null: false
    end
  end
end
