class AddIsGiftCardToLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :is_gift_card, :boolean, default: false
    add_column :spree_products, :product_is_gift_card, :boolean, default: false
  end
end
