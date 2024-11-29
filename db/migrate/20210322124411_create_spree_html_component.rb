class CreateSpreeHtmlComponent < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_html_components do |t|
      t.string :type_of_component
      t.string :name
      t.string :position
      t.integer :html_layout_id
    end
  end
end
