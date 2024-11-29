class RenameStripeConnectedAccountIdToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    rename_column :spree_stores, :stripe_connected_account_id, :stripe_standard_account_id
  end
end
