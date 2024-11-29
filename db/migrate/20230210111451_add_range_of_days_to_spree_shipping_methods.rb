class AddRangeOfDaysToSpreeShippingMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :schedule_days_threshold, :integer, default: 365
  end
end
