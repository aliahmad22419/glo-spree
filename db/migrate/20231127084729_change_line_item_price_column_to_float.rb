class ChangeLineItemPriceColumnToFloat < ActiveRecord::Migration[5.2]
  def up
    change_column :spree_line_items, :custom_price, :decimal, :precision => 16, :scale => 2, default: 0.0
  end

  def down
    change_column :spree_line_items, :custom_price, :integer, default: 0
  end
end
