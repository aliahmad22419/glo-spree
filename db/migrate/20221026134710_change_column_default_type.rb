class ChangeColumnDefaultType < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_ts_giftcards, :send_gift_card_via, :string
    add_column :spree_ts_giftcards, :send_gift_card_via, :integer, default: 1
  end
end
