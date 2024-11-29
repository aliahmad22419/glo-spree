class AddPublishAndActiveIndexToSpreePublishHtmlLayouts < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_publish_html_layouts, :publish
    add_index :spree_publish_html_layouts, :active
    add_index :spree_publish_html_layouts, :html_page_id
    add_index :spree_publish_html_layouts, [:publish,:active]
    add_index :spree_publish_html_layouts, [:publish,:active,:html_page_id],name: 'publish_active_html_page_index'
  end
end
