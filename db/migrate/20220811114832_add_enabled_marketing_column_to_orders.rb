class AddEnabledMarketingColumnToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :enabled_marketing, :boolean, default: false
  end
end
