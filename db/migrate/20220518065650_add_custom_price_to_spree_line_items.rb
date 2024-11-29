class AddCustomPriceToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :custom_price, :integer, default: 0
  end
end
