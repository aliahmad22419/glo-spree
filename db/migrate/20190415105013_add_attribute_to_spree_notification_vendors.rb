class AddAttributeToSpreeNotificationVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_notifications_vendors, :read, :boolean, default: false
  end
end
