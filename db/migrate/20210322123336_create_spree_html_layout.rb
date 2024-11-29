class CreateSpreeHtmlLayout < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_html_layouts do |t|
      t.string :type_of_layout
      t.integer :html_page_id
      t.string :name
    end
  end
end
