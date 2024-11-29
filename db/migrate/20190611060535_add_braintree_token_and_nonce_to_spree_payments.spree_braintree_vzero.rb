# This migration comes from spree_braintree_vzero (originally 20151018123907)
class AddBraintreeTokenAndNonceToSpreePayments < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_payments, :braintree_token, :string
    add_column :spree_payments, :braintree_nonce, :string
  end
end
