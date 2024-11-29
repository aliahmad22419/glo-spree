class AddBarcodeNumberAndUnitCostPriceColumnsToSaleAnalyses < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_sale_analyses, :unit_cost_price, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :spree_sale_analyses, :barcode_number, :string, default: ""
  end
end
