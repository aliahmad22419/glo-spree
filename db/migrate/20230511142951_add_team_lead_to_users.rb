class AddTeamLeadToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :lead, :boolean, default: false
  end
end
