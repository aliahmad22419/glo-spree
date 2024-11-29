class AddSwatchesInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :swatches, :text, array: true, default: []
    add_column :spree_stores, :is_show_swatches, :boolean, default: false
  end
end
