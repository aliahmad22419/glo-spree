class AddCodeInAddress < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_addresses, :phone_code, :string
  end
end
