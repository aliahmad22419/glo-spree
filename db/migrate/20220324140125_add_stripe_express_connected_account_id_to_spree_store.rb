class AddStripeExpressConnectedAccountIdToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :stripe_express_account_id, :string
  end
end
