class AddExpiryDateToTsGiftcard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ts_giftcards, :expiry_date, :date
  end
end
