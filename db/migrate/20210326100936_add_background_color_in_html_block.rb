class AddBackgroundColorInHtmlBlock < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_ui_blocks, :background_color, :string
  end
end
