class AddLogoUrlToSpreeHtmlUiBlocks < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_html_ui_blocks, :logo_url, :string, default: ''
  end
end
