class AddColumnsToMenuItems < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :controller, :string, default: nil
    add_column :menu_items, :actions, :text, array: true, default: []
  end
end
