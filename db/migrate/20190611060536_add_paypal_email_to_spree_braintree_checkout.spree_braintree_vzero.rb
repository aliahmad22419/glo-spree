# This migration comes from spree_braintree_vzero (originally 20151027135109)
class AddPaypalEmailToSpreeBraintreeCheckout < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_braintree_checkouts, :paypal_email, :string
  end
end
