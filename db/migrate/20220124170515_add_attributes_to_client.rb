class AddAttributesToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :ts_email, :string
    add_column :spree_clients, :ts_password, :string
    add_column :spree_clients, :ts_url, :string
  end
end
