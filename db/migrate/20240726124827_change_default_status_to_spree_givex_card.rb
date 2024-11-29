class ChangeDefaultStatusToSpreeGivexCard < ActiveRecord::Migration[6.1]
  def change
    change_column_default :spree_givex_cards, :status, 0
  end
end
