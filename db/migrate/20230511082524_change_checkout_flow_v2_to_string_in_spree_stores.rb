class ChangeCheckoutFlowV2ToStringInSpreeStores < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_stores, :checkout_flow_v2, :string, default: "v1"
    rename_column :spree_stores, :checkout_flow_v2, :checkout_flow
  end
end
