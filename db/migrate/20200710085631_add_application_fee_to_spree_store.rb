class AddApplicationFeeToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :app_fee_type, :string, default: Spree::Payment::GatewayOptions.class_eval { APP_FEE_TYPES[:percentage] }
    add_column :spree_stores, :app_fee, :integer, default: 0
  end
end
