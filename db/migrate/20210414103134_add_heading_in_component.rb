class AddHeadingInComponent < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_components, :heading, :string
  end
end
