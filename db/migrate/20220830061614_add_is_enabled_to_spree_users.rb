class AddIsEnabledToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :is_enabled, :boolean, default: true
  end
end
