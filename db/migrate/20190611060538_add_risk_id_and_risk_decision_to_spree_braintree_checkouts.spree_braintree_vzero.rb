# This migration comes from spree_braintree_vzero (originally 20151202095956)
class AddRiskIdAndRiskDecisionToSpreeBraintreeCheckouts < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_braintree_checkouts, :risk_id, :string
    add_column :spree_braintree_checkouts, :risk_decision, :string
  end
end
