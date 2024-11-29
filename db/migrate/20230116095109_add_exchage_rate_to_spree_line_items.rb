class AddExchageRateToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :exchange_rate, :integer, default: 0
  end
end
