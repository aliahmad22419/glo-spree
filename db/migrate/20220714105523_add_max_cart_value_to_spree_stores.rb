class AddMaxCartValueToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :max_cart_transaction, :float
  end
end
