class AddProductTypeToSaleAnalyses < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_sale_analyses, :product_card_type, :string, default: ""
  end
end
