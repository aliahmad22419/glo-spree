class AddDeliveryModeInProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :delivery_mode, :string
  end
end
