class AddLayoutInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :new_layout, :boolean, default: false
  end
end
