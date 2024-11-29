class CreateSpreeNotificationsVendors < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_notifications_vendors do |t|
      t.belongs_to :vendor, index: true
      t.belongs_to :notification, index: true
    end
  end
end
