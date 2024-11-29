class CreateMenuItems < ActiveRecord::Migration[5.2]
  def change
    create_table :menu_items do |t|
      t.string :name
      t.text :url
      t.string :img_url
      t.boolean :namespace, default: false
      t.text :menu_permission_roles, array: true , default: []
      t.integer :priority, default: 0
      t.boolean :visible, default: false
      t.integer :parent_id

      t.timestamps
    end

  end
end
