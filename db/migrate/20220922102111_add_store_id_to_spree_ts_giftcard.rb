class AddStoreIdToSpreeTsGiftcard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ts_giftcards, :store_id, :integer
    add_column :spree_ts_giftcards, :campaign_id, :integer
    add_column :spree_ts_giftcards, :campaign_body, :text
    add_column :spree_ts_giftcards, :image_url, :string
    add_column :spree_ts_giftcards, :receipient_phone_number, :string
    add_column :spree_ts_giftcards, :send_gift_card_via, :string
  end
end
