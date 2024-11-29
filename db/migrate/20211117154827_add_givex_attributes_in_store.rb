class AddGivexAttributesInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :givex_url, :string, default: ''
    add_column :spree_stores, :givex_password, :string, default: ''
    add_column :spree_stores, :givex_user, :string, default: ''
  end
end
