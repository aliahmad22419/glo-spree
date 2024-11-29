class AddLayoutInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :new_layout, :boolean, default: false
  end
end
