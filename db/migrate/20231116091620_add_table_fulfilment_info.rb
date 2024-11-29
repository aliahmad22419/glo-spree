class AddTableFulfilmentInfo < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_fulfilment_infos do |t|
      t.string :gift_card_number
      t.string :serial_number
      t.string :currency
      t.decimal :customer_shippment_paid, precision: 10, scale: 2 
      t.datetime :processed_date
      t.string :postage_currency
      t.bigint :postage_fee
      t.string :receipt_reference
      t.string :courier_company
      t.string :tracking_number
      t.string :comment
      t.boolean :accurate_submition, default: false
      t.bigint  :shipment_id
      t.bigint  :user_id
      t.timestamps
    end

    add_column :spree_shipments, :fulfilment_status, :string, :default => "pending"
    
  end
end
