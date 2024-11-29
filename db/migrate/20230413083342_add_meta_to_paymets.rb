class AddMetaToPaymets < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_payments, :meta, :jsonb
  end
end
