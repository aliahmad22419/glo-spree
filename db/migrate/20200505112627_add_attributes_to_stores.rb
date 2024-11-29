class AddAttributesToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :fb_username, :string, default: ""
    add_column :spree_stores, :insta_username, :string, default: ""
    add_column :spree_stores, :twitter_username, :string, default: ""
    add_column :spree_stores, :pinterest_username, :string, default: ""
    add_column :spree_stores, :linkedin_username, :string, default: ""
  end
end
