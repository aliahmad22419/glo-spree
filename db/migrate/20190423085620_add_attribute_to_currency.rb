class AddAttributeToCurrency < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_currencies, :vendor_id, :integer
  end
end
