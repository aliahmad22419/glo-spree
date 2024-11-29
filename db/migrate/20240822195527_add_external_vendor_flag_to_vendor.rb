class AddExternalVendorFlagToVendor < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_vendors, :external_vendor, :boolean, default: false
  end
end
