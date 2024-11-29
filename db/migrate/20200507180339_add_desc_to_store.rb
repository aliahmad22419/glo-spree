class AddDescToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :description, :text, default: ""
  end
end
