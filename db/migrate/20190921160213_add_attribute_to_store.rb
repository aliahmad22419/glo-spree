class AddAttributeToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :duty, :float, default: 0
    add_column :spree_stores, :duty_currency, :string, default: ''
  end
end
