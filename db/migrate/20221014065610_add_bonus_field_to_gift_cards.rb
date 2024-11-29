class AddBonusFieldToGiftCards < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ts_giftcards, :bonus, :boolean, default: false
    add_column :spree_givex_cards, :bonus, :boolean, default: false
  end
end
