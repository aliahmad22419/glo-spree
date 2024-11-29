class CreateMenuItemUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :menu_item_users do |t|
      t.integer :menu_item_id
      t.integer :user_id
      t.integer :parent_id
      t.boolean :visible

      t.timestamps
    end
  end
end
