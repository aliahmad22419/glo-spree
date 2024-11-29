class AddBarcodeKeyQrcodeKeyColumnsToSpreeTsGiftcards < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ts_giftcards, :barcode_key, :string
    add_column :spree_ts_giftcards, :qrcode_key, :string
  end
end
