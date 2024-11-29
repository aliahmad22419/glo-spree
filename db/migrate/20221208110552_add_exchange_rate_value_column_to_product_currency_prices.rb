class AddExchangeRateValueColumnToProductCurrencyPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_product_currency_prices, :exchange_rate_value, :float, default: 1.0
  end
end
