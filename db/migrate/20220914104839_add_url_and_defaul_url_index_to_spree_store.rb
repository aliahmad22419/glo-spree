class AddUrlAndDefaulUrlIndexToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_stores, [:url, :default_url]
    add_index :spree_stores, :url
    add_index :spree_stores, :default_url
  end
end
