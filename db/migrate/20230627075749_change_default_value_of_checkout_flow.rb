class ChangeDefaultValueOfCheckoutFlow < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_stores, :checkout_flow, :string, :default => "v1"
  end
end
