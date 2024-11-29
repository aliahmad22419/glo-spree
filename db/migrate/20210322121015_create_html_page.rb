class CreateHtmlPage < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_html_pages do |t|
      t.string :url
      t.integer :store_id
    end
  end
end
