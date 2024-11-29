class AddAutoApproveProductsToSpreeClients < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :auto_approve_products, :boolean, default: false
  end
end
