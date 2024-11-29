class CreateSaleAnalyses < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_sale_analyses do |t|
      t.string :order_number
      t.string :storefront
      t.string :time_zone
      t.datetime :date_placed
      t.string :status
      t.string :customer
      t.string :currency
      t.datetime :delivery_pickup_date
      t.datetime :shipped_date
      t.string :delivery_pickup_time
      t.string :shipped_time
      t.decimal :tax_inclusive
      t.decimal :additional_tax
      t.text :tags, array: true, default: []
      t.decimal :total
      t.string :vendor
      t.datetime :time_placed
      t.string :order_status
      t.string :customer_full_name
      t.string :customer_address
      t.string :customer_first_name
      t.string :customer_last_name
      t.string :shipping_delivery_country
      t.string :customer_phone
      t.string :customer_email
      t.string :product_name
      t.string :product_sku
      t.string :vendor_sku
      t.string :variant
      t.integer :product_quantity
      t.decimal :product_price
      t.string :order_currency
      t.string :vendor_currency
      t.decimal :exchange_rate
      t.decimal :sub_total
      t.decimal :shipping_amount
      t.decimal :total_shipping_amount
      t.decimal :discount_amount
      t.decimal :associated_order_value
      t.string :shipping_method
      t.string :tags
      t.text :gift_card_number
      t.text :gift_card_iso_number
      t.text :special_message
      t.string :card_type
      t.string :recipient_name
      t.string :recipient_first_name
      t.string :recipient_last_name
      t.string :recipient_email
      t.string :recipient_phone_number
      t.string :marketing_enabled
      t.string :product_tag
      t.string :promo_code
      t.string :payment_method
      t.string :order_shipped
      t.integer :order_id
      t.integer :line_item_id

      t.timestamps
    end
  end
end
