class AddHawkAttributesToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :hawk_username, :string, default: ''
    add_column :spree_stores, :hawk_password, :string, default: ''
    add_column :spree_stores, :hawk_store_channel_code, :string, default: ''
    add_column :spree_stores, :hawk_api_url, :string, default: ''
  end
end
