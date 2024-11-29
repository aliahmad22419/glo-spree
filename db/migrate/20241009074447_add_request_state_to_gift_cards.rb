class AddRequestStateToGiftCards < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_ts_giftcards, :request_state, :integer, default: 0
    add_column :spree_givex_cards, :request_state, :integer, default: 0
  end
end
