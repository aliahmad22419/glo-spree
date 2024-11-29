class AddBarcodeAndCostPriceColumnsToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :unit_cost_price, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :spree_variants, :unit_cost_price, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :spree_products, :barcode_number, :string, default: ""
    add_column :spree_variants, :barcode_number, :string, default: ""
  end
end
