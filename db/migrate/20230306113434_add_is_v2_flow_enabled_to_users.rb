class AddIsV2FlowEnabledToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :is_v2_flow_enabled, :boolean, :default => false  
  end
end