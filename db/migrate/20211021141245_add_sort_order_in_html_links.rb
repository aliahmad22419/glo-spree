class AddSortOrderInHtmlLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_links, :sort_order, :integer, :default => 1
  end
end
