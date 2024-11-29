class CreateSpreeGallery < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_galleries do |t|
      t.integer :attachment_id
      t.integer :client_id
    end
  end
end
