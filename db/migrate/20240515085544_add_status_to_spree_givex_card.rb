class AddStatusToSpreeGivexCard < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_givex_cards, :status, :integer, default: 1
  end
end
