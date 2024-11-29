class AddLocalStoreIdsToSpreeProductCurrencyPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_product_currency_prices, :local_store_ids, :text, array: true, default: []
  end
end
