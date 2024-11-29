class AddAttributeToStor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :ts_gift_card_url, :string
  end
end
