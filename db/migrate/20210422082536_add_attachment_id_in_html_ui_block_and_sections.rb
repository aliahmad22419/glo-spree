class AddAttachmentIdInHtmlUiBlockAndSections < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_block_sections, :attachment_id, :integer
    add_column :spree_html_ui_blocks, :attachment_id, :integer
  end
end
