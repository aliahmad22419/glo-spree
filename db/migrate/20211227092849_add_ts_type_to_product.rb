class AddTsTypeToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :ts_type, :string, default: ''
    add_column :spree_stores, :ts_gift_card_email, :string, default: ''
    add_column :spree_stores, :ts_gift_card_password, :string, default: ''
  end
end
