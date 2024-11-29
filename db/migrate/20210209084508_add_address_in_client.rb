class AddAddressInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :client_address_id, :integer
  end
end
