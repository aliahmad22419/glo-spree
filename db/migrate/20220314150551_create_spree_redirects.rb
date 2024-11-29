class CreateSpreeRedirects < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_redirects do |t|
      t.string :type_redirect
      t.string :from
      t.string :to
      t.integer :client_id
      t.integer :store_id

      t.timestamps
    end
  end
end
