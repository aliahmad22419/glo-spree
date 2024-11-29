class AddFieldsToAddress < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_addresses, :apartment_no, :string
    add_column :spree_addresses, :estate_name, :string
    add_column :spree_addresses, :region, :string
    add_column :spree_addresses, :district, :string
  end
end
