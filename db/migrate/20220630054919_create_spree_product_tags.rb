class CreateSpreeProductTags < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_product_tags do |t|
      t.integer :client_id
      t.string :name
      t.timestamps
    end
  end
end
