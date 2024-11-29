class CreateApplePassbooks < ActiveRecord::Migration[5.2]
  def change
    create_table :apple_passbooks do |t|
      t.json       :pass
      t.string     :p12_password
      t.references :store, null: false

      t.timestamps
    end
  end
end
