class AddStoreSettingAttributeToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :google_translator, :boolean, default: false
    add_column :spree_stores, :ask_seller, :boolean, default: false
    add_column :spree_stores, :vendor_visibility, :boolean, default: false
    add_column :spree_stores, :mailchip, :boolean, default: false
  end
end
