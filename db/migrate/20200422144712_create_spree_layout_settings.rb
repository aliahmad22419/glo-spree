class CreateSpreeLayoutSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_layout_settings do |t|
      t.text :preferences
      t.references :store

      t.timestamps
    end
  end
end
