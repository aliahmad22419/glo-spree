class CreateSpreePersonalization < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_personalizations do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
