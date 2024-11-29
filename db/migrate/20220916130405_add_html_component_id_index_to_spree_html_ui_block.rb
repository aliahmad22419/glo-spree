class AddHtmlComponentIdIndexToSpreeHtmlUiBlock < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_html_ui_blocks, :html_component_id
  end
end
