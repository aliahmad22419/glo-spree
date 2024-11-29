class AddPaymentIntentIdToSpreeOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :payment_intent_id, :string
  end
end
