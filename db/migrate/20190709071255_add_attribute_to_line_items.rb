class AddAttributeToLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :vendor_id, :integer
    add_column :spree_line_items, :vendor_name, :string
    add_column :spree_line_items, :store_id, :integer
    add_column :spree_line_items, :message, :text
    add_column :spree_line_items, :glo_api, :boolean
  end
end
