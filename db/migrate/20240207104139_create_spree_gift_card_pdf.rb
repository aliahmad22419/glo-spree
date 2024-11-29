class CreateSpreeGiftCardPdf < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_gift_card_pdfs do |t|
      t.text :preferences
      t.references :store

      t.timestamps
    end
  end
end
