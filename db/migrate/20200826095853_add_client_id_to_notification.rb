class AddClientIdToNotification < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_notifications, :client_id, :integer
  end
end
