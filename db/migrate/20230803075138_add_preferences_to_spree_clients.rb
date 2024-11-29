class AddPreferencesToSpreeClients < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :preferences, :text
  end
end
