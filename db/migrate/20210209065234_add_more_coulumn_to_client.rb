class AddMoreCoulumnToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :already_selling, :boolean, default: false
    add_column :spree_clients, :current_revenue, :decimal
    add_column :spree_clients, :type_of_industry, :string
    add_column :spree_clients, :selling_platform, :string
  end
end
