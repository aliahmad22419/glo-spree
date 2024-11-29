class AddIndexToSpreeProductCurrencyPrice < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_product_currency_prices, :product_id
  end
end
