class AddV3BillingAddressToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :enable_v3_billing, :boolean, default: false
  end
end
