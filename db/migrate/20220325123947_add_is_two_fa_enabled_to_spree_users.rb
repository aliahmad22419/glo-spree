class AddIsTwoFaEnabledToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :is_two_fa_enabled, :boolean, default: false
  end
end
