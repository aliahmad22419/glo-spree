class AddMissingShipmentsOrGiftCardsToSpreeOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_orders, :error_log_status, :integer, default: 0
  end
end