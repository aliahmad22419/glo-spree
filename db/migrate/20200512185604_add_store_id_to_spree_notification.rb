class AddStoreIdToSpreeNotification < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_notifications, :store_id, :integer
  end
end
