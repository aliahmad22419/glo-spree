class AddActiveCardToGivexCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :active_card, :boolean, default:  false
  end
end