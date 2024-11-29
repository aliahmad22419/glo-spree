class CreateSpreeProductCurrencyPrices < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_product_currency_prices do |t|
      t.string :from_currency
      t.string :to_currency
      t.integer :client_id
      t.integer :vendor_id
      t.integer :product_id
      t.integer :vendor_country_id
      t.float :non_exchanged_price
      t.float :price
      t.float :local_area_price
      t.float :wide_area_price
      t.float :restricted_area_price

      t.index :client_id
      t.index :vendor_id
      t.index :vendor_country_id
      t.timestamps
    end
  end
end
