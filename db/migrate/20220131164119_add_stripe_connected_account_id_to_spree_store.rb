class AddStripeConnectedAccountIdToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :stripe_connected_account_id, :string, default: nil
    # copy client account id to all stores of that client
    Spree::Store.find_each { |store| store.update_attribute(:stripe_connected_account_id, store.client.stipe_connected_account_id) }
  end
end
