class AddAmountToSpreeFulfilmentInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_fulfilment_infos, :amount, :decimal, precision: 10, scale: 2
    add_column :spree_fulfilment_infos, :quantity, :integer
  end
end
