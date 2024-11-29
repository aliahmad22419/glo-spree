class AddUserIdColumnToFulfilmentTables < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_fulfilment_teams, :creator_id, :bigint
    add_column :spree_fulfilment_teams, :created_at, :datetime
    add_column :spree_fulfilment_teams, :updated_at, :datetime
    add_column :spree_zones, :creator_id, :bigint
  end
end
