class ChangePriorityMenuItemFieldFromIntegerToDecimal < ActiveRecord::Migration[5.2]
  def change
    change_column :menu_items, :priority, :decimal, precision: 8, scale: 2,  default: 0.0, null: false
  end
end

