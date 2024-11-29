class AddCurrenyToGiftCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_gift_cards, :currency, :string
  end
end
