class AddAttributesToSpreeHtmlUiBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :cta_label, :string, default: ''
    add_column :spree_html_ui_blocks, :cta_link, :string, default: ''

  end
end
