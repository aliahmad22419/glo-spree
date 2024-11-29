class CreateSpreeRegistrations < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_registrations do |t|
      t.references :user
      t.references :store

      t.timestamps
    end
  end
end
