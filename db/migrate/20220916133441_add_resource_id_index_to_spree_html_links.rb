class AddResourceIdIndexToSpreeHtmlLinks < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_html_links, :resource_id
  end
end
