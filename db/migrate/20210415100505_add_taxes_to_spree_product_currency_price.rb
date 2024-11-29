class AddTaxesToSpreeProductCurrencyPrice < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_product_currency_prices, :taxes, :text, array: true, default: []
  end
end
