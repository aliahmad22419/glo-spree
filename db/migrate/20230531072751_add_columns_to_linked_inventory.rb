class AddColumnsToLinkedInventory < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_linked_inventories, :master_variant_id, :bigint
    add_column :spree_linked_inventories, :quantity, :bigint
  end
end
