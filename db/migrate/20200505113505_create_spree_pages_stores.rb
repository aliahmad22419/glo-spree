class CreateSpreePagesStores < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_pages_stores do |t|
      t.references :store, index: true
      t.references :page, index: true
      t.timestamps
    end
  end
end
