class AddShowAllGiftCardDigitsToSpreeClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :show_all_gift_card_digits, :boolean,default: true
  end
end
