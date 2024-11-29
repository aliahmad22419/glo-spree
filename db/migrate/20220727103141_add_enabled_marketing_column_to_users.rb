class AddEnabledMarketingColumnToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :enabled_marketing, :boolean, default: false
  end
end