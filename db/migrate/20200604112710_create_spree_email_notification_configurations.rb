class CreateSpreeEmailNotificationConfigurations < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_email_notification_configurations do |t|
      t.text :preferences
      t.references :store
      
      t.timestamps
    end
  end
end
