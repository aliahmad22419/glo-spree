class AddRefundReasonUniqueNamePerClient < ActiveRecord::Migration[5.2]
  def up
    remove_index :spree_refund_reasons, name: "index_spree_refund_reasons_on_lower_name"
    execute "CREATE UNIQUE INDEX index_spree_refund_reasons_on_lower_name_and_client_id ON spree_refund_reasons(lower(name), client_id)"
  end

  def down
    add_index :spree_refund_reasons, "lower((name)::text)", name: "index_spree_refund_reasons_on_lower_name", unique: true
    remove_index :spree_refund_reasons, name: "index_spree_refund_reasons_on_lower_name_and_client_id"
  end
end
