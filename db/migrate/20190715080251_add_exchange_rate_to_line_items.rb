class AddExchangeRateToLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :exchange_rate_value, :float, default: 1
  end
end
