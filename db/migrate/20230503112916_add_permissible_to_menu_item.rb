class AddPermissibleToMenuItem < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :permissible, :boolean, default: true
    add_column :menu_item_users, :permissible, :boolean, default: true

    add_index :menu_items, [:url, :name], unique: true
    add_index :menu_item_users, [:menu_item_id, :user_id], unique: true
  end
end
