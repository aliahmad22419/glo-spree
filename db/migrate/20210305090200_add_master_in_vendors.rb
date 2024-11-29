class AddMasterInVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :master, :boolean, default: false
  end
end
