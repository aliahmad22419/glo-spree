class AddServiceLoginUserIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :service_login_user_id, :bigint
  end
end
