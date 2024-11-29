class ChangeColumnNameOfSpreePagesOrderAttribute < ActiveRecord::Migration[5.2]
  def change
    rename_column :spree_pages, :order, :sort_order
  end
end
