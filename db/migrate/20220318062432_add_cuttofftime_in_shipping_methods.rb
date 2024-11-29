class AddCuttofftimeInShippingMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :cutt_off_time, :integer, default: 0
  end
end
