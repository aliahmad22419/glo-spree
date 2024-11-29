# This migration comes from spree_braintree_vzero (originally 20151002094655)
class AddBraintreeIdToSpreeAddresses < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_addresses, :braintree_id, :string
  end
end
