class AddAllowMenuItemsToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
      add_column :spree_users, :allow_menu_items, :text, array: true, default: ["Home", "Orders", "Products", "Gift Cards", "Conversations", "Vendors", "Stores", "Categories", "Gallery", "Settings"]
  end
end
