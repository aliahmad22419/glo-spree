class AddSalePriceToSpreeProductCurrencyPrice < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_product_currency_prices, :sale_price, :float, default: 0.0
  end
end
