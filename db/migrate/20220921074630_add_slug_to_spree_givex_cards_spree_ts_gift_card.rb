class AddSlugToSpreeGivexCardsSpreeTsGiftCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :slug, :string
    add_index :spree_givex_cards, :slug, unique: true
    add_column :spree_ts_giftcards, :slug, :string
    add_index :spree_ts_giftcards, :slug, unique: true
    Spree::GivexCard.all.each{|card| card.set_slug; card.save}
    Spree::TsGiftcard.all.each{|card| card.set_slug; card.save}
  end
end
