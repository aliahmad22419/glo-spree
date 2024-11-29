class CreateSpreeHawkCards < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_hawk_cards do |t|
      t.text :hawk_response
      t.bigint :transaction_code
      t.bigint :bar_code_number
      t.float :balance
      t.date :expiry_date
      t.integer :pin
      t.string :supplier_reference_no
      t.string :url
      t.string :sku
      t.string :delivery_email
      t.string :card_type
      t.integer :order_id
      t.integer :user_id
      t.integer :line_item_id
      t.string :customer_first_name
      t.string :customer_last_name
    end
  end
end
