class AddTcAndMarketingAttributesToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :enable_checkout_terms, :boolean, default: false
    add_column :spree_stores, :checkout_terms, :string, default: ""
    add_column :spree_stores, :enable_marketing, :boolean, default: false
    add_column :spree_stores, :marketing_statement, :string, default: ""
  end
end
