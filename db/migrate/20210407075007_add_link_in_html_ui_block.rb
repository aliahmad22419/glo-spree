class AddLinkInHtmlUiBlock < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :link, :string, default: ""
  end
end
