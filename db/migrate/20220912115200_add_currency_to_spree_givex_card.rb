class AddCurrencyToSpreeGivexCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :currency, :string, default: ''
  end
end
