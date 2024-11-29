class CreateVendorSaleAnalyses < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_vendor_sale_analyses do |t|
      t.string :number
      t.string :storefront
      t.datetime :completed_at
      t.string :status
      t.string :email
      t.string :currency
      t.string :delivery_pickup_date
      t.string :delivery_pickup_time
      t.string :shipped_date
      t.string :shipped_time
      t.decimal :tax_inclusive
      t.decimal :additional_tax
      t.string :tags
      t.decimal :total
      t.integer :vendor_id
      t.integer :order_id

      t.timestamps
    end
  end
end
