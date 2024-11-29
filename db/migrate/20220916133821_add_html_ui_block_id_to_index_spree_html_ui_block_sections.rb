class AddHtmlUiBlockIdToIndexSpreeHtmlUiBlockSections < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_html_ui_block_sections, :html_ui_block_id
  end
end
