class CreateLineItemExchangeRates < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_line_item_exchange_rates do |t|
      t.string :from_currency
      t.string :to_currency
      t.float :exchange_rate, default: 1
      t.float :mark_up, default: 0
      t.references :line_item

      t.timestamps
    end
  end
end
