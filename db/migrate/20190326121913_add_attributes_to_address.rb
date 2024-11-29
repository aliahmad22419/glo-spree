class AddAttributesToAddress < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_addresses, :email, :string
  end
end
