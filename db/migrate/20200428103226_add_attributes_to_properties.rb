class AddAttributesToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_properties, :filterable, :boolean, default: false
    add_column :spree_properties, :values, :text, default: ''
  end
end
