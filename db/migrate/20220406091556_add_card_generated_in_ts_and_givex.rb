class AddCardGeneratedInTsAndGivex < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :card_generated, :boolean, default: false
    add_column :spree_ts_giftcards, :card_generated, :boolean, default: false
  end
end
