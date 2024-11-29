class AddSwatchesInProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :color_swatches, :text, array: true, default: []
    add_column :spree_products, :size_swatches, :text, array: true, default: []

  end
end
