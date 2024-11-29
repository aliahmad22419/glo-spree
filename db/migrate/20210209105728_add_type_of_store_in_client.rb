class AddTypeOfStoreInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :multi_vendor_store, :boolean, default: false
  end
end
