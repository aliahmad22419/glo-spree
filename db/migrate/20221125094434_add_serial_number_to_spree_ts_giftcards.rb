class AddSerialNumberToSpreeTsGiftcards < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ts_giftcards, :serial_number, :string
  end
end
