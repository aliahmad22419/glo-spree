class AddV3DigitalAddress < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_addresses, :is_v3_flow_address, :boolean, default: false
  end
end
