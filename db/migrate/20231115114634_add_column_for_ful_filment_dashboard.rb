class AddColumnForFulFilmentDashboard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_zones, :fulfilment_zone, :boolean, default: false
    add_column :spree_zones, :zone_code, :string
  end
end
