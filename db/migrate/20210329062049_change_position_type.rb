class ChangePositionType < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_html_components, :position, 'integer USING CAST(position AS integer)'
  end
end
