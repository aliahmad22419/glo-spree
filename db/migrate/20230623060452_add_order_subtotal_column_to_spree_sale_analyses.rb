class AddOrderSubtotalColumnToSpreeSaleAnalyses < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_sale_analyses, :order_subtotal, :decimal, precision: 16, scale: 2, default: 0.0, null: false
  end
end
