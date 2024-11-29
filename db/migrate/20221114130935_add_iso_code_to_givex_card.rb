class AddIsoCodeToGivexCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :iso_code, :string
  end
end
