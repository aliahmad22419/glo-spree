class CreateSpreeInventory < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_linked_inventories do |t|
      t.bigint :vendor_group_id
      t.string :name
      t.string :description
      t.datetime :deleted_at

      t.timestamps
      t.index :vendor_group_id, name: :index_spree_inventories_on_vendor_group_id
    end
  end
end
