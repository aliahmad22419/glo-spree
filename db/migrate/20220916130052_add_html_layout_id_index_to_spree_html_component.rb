class AddHtmlLayoutIdIndexToSpreeHtmlComponent < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_html_components, :html_layout_id
  end
end
