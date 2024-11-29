class AddActAsMerchantToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_clients, :act_as_merchant, :boolean, default: false
  end
end
