class AddCustomerSupportEmailToSpreeClients < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :customer_support_email, :string
  end
end
