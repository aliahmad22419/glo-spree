class CreateSpreePropertiesStores < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_properties_stores do |t|
      t.references :store, index: true
      t.references :property, index: true
      t.timestamps
    end
  end
end
