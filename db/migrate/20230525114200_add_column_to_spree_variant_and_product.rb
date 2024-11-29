class AddColumnToSpreeVariantAndProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_variants, :linked_inventory_id, :bigint 
    add_column :spree_products, :linked, :boolean, default: false
    add_column :spree_vendors, :vendor_group_id, :bigint 
  end
end
