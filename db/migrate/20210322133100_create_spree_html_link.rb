class CreateSpreeHtmlLink < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_html_links do |t|
      t.references :resource, polymorphic: true
      t.string :link
    end
  end
end
