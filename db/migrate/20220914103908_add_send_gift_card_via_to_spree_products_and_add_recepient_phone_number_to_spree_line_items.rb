class AddSendGiftCardViaToSpreeProductsAndAddRecepientPhoneNumberToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :send_gift_card_via, :integer, default: 1
    add_column :spree_line_items, :receipient_phone_number, :string
    add_column :spree_givex_cards, :receipient_phone_number, :string
    add_column :spree_givex_cards, :send_gift_card_via, :integer, default: 1
    add_column :spree_clients, :from_phone_number, :string, default: ''
  end
end
