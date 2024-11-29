class AddV3FlowAddressIdInStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :v3_flow_address_id, :bigint
  end
end
