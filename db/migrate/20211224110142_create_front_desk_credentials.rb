class CreateFrontDeskCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_front_desk_credentials do |t|
      t.string :tsgifts_email
      t.string :tsgifts_password
      t.integer :user_id

      t.timestamps
    end
  end
end
