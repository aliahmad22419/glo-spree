class AddSkuToLineItemCustomization < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_item_customizations, :sku, :string
  end
end
