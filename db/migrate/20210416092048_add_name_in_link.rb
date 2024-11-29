class AddNameInLink < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_links, :name, :string
  end
end
