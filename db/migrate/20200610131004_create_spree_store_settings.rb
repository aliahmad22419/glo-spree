class CreateSpreeStoreSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_store_settings do |t|
      t.text :preferences
      t.references :store
      
      t.timestamps
    end
  end
end
