class AddLineUsernameToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :line_username, :string, default: ""
  end
end
