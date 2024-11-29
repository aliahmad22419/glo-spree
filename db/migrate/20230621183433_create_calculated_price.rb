class CreateCalculatedPrice < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_calculated_prices do |t|
      t.string  :to_currency
      t.bigint  :calculated_price_id
      t.string  :calculated_price_type
      t.jsonb :calculated_value, null: false, default: {}
      t.jsonb :meta, null: false, default: {}
    end
    add_index :spree_calculated_prices, [:calculated_price_id]
    add_index :spree_calculated_prices, [:calculated_price_type]
  end
end

