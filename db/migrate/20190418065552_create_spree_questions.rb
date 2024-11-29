class CreateSpreeQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_questions do |t|
      t.string :title
      t.boolean :is_replied, default: false
      t.boolean :archived, default: false
      t.integer :vendor_id
      t.integer :product_id
      t.string :status, default: "pending"
      t.timestamps null: false
    end
  end
end
