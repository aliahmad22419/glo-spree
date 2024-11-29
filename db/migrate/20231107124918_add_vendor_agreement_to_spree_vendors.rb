class AddVendorAgreementToSpreeVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :agreed_to_client_terms, :boolean, default: false
  end
end
