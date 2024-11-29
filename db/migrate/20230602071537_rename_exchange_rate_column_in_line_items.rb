class RenameExchangeRateColumnInLineItems < ActiveRecord::Migration[5.2]
  def change
    rename_column :spree_line_items, :exchange_rate, :item_exchange_rate
  end
end
