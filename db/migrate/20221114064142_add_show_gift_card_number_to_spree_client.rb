class AddShowGiftCardNumberToSpreeClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :show_gift_card_number, :boolean,default: true
  end
end
