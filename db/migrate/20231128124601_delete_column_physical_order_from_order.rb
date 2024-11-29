class DeleteColumnPhysicalOrderFromOrder < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_orders, :physical_order
  end
end