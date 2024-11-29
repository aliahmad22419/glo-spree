class AddSendGiftCardViaToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :send_gift_card_via, :integer
  end
end
