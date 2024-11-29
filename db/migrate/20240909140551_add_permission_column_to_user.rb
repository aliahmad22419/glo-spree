class AddPermissionColumnToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :can_manage_sub_user, :boolean, default: false
  end
end
