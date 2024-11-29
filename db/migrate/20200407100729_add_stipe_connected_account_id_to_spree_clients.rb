class AddStipeConnectedAccountIdToSpreeClients < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :stipe_connected_account_id, :string
  end
end
