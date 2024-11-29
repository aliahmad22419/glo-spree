class AddDescriptionToSpreeHtmlUiBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :banner_item_description, :text, default: ''
  end
end
