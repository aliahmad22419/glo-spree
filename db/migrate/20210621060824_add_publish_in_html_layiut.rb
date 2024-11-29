class AddPublishInHtmlLayiut < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_layouts, :publish, :boolean, default: false
  end
end
