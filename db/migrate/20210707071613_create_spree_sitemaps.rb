class CreateSpreeSitemaps < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_sitemaps do |t|
      t.references :client
      t.integer :file_count
      t.string :invalid_store_ids

      t.timestamps
    end
  end
end
