class CreateSpreeCountriesStores < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_countries_stores do |t|
      t.references :store, index: true
      t.references :country, index: true
      t.timestamps
    end
  end
end
