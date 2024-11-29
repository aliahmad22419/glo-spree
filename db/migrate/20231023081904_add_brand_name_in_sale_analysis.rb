class AddBrandNameInSaleAnalysis < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_sale_analyses, :brand_name, :string, default: ""
  end
end
