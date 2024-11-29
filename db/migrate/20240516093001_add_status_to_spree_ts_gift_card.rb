class AddStatusToSpreeTsGiftCard < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_ts_giftcards, :status, :integer, default: 0
  end
end
