class AddFieldsToUsersAndAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :is_iframe_user, :boolean, default: false
    add_column :spree_users, :verified, :boolean, default: false
    add_column :spree_addresses, :credit_card_descriptor, :string
  end
end
