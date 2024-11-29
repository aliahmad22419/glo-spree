class AddReferenceNumberToSpreeTsGiftcards < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_ts_giftcards, :reference_number, :string
    add_index :spree_ts_giftcards, :reference_number, unique: true
  end
end
