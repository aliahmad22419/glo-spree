class CreateSpreeCryptoWallet < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_crypto_wallets do |t|
      t.decimal :crypto_amount, precision: 16, scale: 2
      t.string :crypto_currency
      t.string :customer_id
      t.string :source_name
      t.string :track_id
      t.string :status
      t.integer :payment_method_id
      t.integer :user_id

      t.timestamps

      t.index ["user_id"], name: "index_spree_crypto_wallets_on_user_id"
      t.index [:payment_method_id], name: "index_spree_crypto_wallets_on_payment_method_id"
    end
  end
end
