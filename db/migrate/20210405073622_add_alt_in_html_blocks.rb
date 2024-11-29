class AddAltInHtmlBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :alt, :string
  end
end
