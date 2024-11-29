class CreateSpreeEmbbedWidget < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_embed_widgets do |t|
      t.string :site_domain
      t.references :vendor
      t.timestamps
    end
  end
end
