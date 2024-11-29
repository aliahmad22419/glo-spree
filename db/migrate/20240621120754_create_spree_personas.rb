class CreateSpreePersonas < ActiveRecord::Migration[6.1]
  def change
    create_table :spree_personas do |t|
      t.string :name
      t.integer :persona_code, default: 0
      t.references :client, index: true
      t.text :store_ids, array: true, default: []
      t.text :menu_item_ids, array: true, default: []
      t.text :campaign_ids, array: true, default: []

      t.timestamps
    end
  end
end
