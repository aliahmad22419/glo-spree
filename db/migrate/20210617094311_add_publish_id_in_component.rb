class AddPublishIdInComponent < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_html_components, :publish_html_layout_id, :integer
  end
end
