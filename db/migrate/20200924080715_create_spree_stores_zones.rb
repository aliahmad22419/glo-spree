class CreateSpreeStoresZones < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stores_zones do |t|
      t.references :zone
      t.references :store
    end
  end
end
