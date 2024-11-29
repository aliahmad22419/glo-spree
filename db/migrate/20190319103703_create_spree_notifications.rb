class CreateSpreeNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_notifications do |t|
      t.text :message
      t.timestamps null: false
    end
  end
end
