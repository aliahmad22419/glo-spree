class CreateSpreeVendorGroup < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_vendor_groups do |t|
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
