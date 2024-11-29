class AddAttributesToPages < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_pages, :url, :string, default: ""
    add_column :spree_pages, :meta_desc, :string, default: ""
    add_column :spree_pages, :static_page, :boolean, default: false
  end
end
