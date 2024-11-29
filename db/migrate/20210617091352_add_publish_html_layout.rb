class AddPublishHtmlLayout < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_publish_html_layouts do |t|
      t.string :type_of_layout
      t.integer :html_page_id
      t.string :name
      t.integer :version_number
      t.boolean :active, default: false
      t.boolean :publish, default: false
    end
  end
end
