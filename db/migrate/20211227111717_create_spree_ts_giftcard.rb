class CreateSpreeTsGiftcard < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_ts_giftcards do |t|
      t.string :number
      t.string :customer_email
      t.float :balance
      t.float :pin
      t.integer :user_id
      t.integer :line_item_id
      t.integer :order_id
      t.text :response
      t.string :customer_first_name, default: ""
      t.string :customer_last_name, default: ""
    end
  end
end
