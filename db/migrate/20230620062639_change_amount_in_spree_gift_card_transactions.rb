class ChangeAmountInSpreeGiftCardTransactions < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_gift_card_transactions, :amount, :decimal, precision: 16, scale: 2
  end
end
