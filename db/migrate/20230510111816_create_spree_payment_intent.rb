class CreateSpreePaymentIntent < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_payment_intents do |t|
      t.string :track_id
      t.decimal :amount,  precision: 16, scale: 2, nil: false
      t.string :currency, nil: false
      t.string :method_type
      t.string :intentable_type
      t.integer :intentable_id
      t.integer :order_id
      t.integer :state, default: 0 

      t.timestamps
      t.index ["order_id"], name: "index_spree_payment_intents_on_order_id"
    end
  end
end
