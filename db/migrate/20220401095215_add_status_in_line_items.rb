class AddStatusInLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :status, :string, default: ""
  end
end
