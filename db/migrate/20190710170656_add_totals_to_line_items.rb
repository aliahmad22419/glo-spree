class AddTotalsToLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :customizations_total, :float
    add_column :spree_line_items, :sub_total, :float
  end
end
