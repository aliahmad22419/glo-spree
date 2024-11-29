class AddPageTitleAttributeToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :page_title, :text, default: ""
  end
end
