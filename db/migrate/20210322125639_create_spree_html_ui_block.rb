class CreateSpreeHtmlUiBlock < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_html_ui_blocks do |t|
      t.string :title
      t.string :heading
      t.string :caption
      t.string :text_allignment
      t.string :font_color
      t.string :position
      t.string :type_of_html_ui_block
      t.integer :html_component_id
    end
  end
end
