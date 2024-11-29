class CreateSpreeReports < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_reports do |t|
      t.string :feed_type
      t.string :email
      t.integer :client_id
      t.integer :store_id
      t.timestamps
    end
  end
end
