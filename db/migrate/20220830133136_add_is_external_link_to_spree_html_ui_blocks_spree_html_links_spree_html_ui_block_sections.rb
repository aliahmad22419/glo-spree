class AddIsExternalLinkToSpreeHtmlUiBlocksSpreeHtmlLinksSpreeHtmlUiBlockSections < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :is_external_link, :boolean, default: false
    add_column :spree_html_links, :is_external_link, :boolean, default: false
    add_column :spree_html_links, :link_type, :integer, default: 0
    add_column :spree_html_ui_block_sections, :is_external_link, :boolean, default: false
  end
end
