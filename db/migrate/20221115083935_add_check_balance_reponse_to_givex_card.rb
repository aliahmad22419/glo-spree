class AddCheckBalanceReponseToGivexCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :check_balance_reponse, :string
  end
end
