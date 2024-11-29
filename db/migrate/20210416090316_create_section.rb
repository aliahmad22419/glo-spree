class CreateSection < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_html_ui_block_sections do |t|
      t.string :name
      t.string :type
      t.integer :html_ui_block_id
      t.string :alt
      t.string :link
      t.integer :position
    end
  end
end
