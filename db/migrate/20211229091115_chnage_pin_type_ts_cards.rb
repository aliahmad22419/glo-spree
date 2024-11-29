class ChnagePinTypeTsCards < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_ts_giftcards, :pin, :string
  end
end
