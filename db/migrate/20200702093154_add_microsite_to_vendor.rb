class AddMicrositeToVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :microsite, :boolean, default: true
  end
end
