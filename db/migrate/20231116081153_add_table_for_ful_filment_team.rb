class AddTableForFulFilmentTeam < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_fulfilment_teams do |t|
      t.string :name
      t.string :code
    end

    create_table :spree_fulfilment_teams_zones do |t|
      t.bigint :fulfilment_team_id
      t.bigint :zone_id
    end

    create_table :spree_fulfilment_teams_users do |t|
      t.bigint :fulfilment_team_id
      t.bigint :user_id
    end

    add_column :spree_orders, :zone_id, :bigint
    add_column :spree_orders, :physical_order, :boolean, :default =>false
    
  end
end
