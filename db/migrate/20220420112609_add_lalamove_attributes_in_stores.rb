class AddLalamoveAttributesInStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :lalamove_sk, :string, default: ''
    add_column :spree_stores, :lalamove_pk, :string, default: ''
    add_column :spree_stores, :lalamove_market, :string, default: ''
    add_column :spree_stores, :lalamove_url, :string, default: ''
  end
end
