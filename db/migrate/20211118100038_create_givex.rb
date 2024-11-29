class CreateGivex < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_givex_cards do |t|
      t.bigint    :transaction_code
      t.string    :givex_number
      t.string    :givex_transaction_reference
      t.string    :customer_email
      t.float     :balance
      t.date      :expiry_date
      t.text      :receipt_message
      t.text      :comments
      t.integer   :user_id
      t.integer   :line_item_id
      t.integer   :order_id
      t.integer   :line_item_customization_id
      t.text      :givex_response

    end
  end
end
