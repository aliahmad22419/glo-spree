class ChangeHtmlUiBlockSectionColumnType < ActiveRecord::Migration[5.2]
  def change
    rename_column :spree_html_ui_block_sections, :type, :type_of_section
  end
end
