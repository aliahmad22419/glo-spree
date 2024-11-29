class CreateSpreeJsonFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_json_files do |t|
      t.references :client
      t.string :source
      
      t.timestamps
    end
  end
end
