class AddTimestampsToPageBuilder < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :spree_html_pages
    add_timestamps :spree_html_layouts
    add_timestamps :spree_html_components
    add_timestamps :spree_html_ui_blocks
    add_timestamps :spree_html_links
    add_timestamps :spree_html_ui_block_sections
    add_timestamps :spree_publish_html_layouts
  end
end
