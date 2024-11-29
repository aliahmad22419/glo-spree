class AddScheduledFullfilledColumnsToShippingMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :scheduled_fulfilled, :boolean, default: false
  end
end
