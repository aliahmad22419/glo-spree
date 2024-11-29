class AddLalamoveAttributesInShipment < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :lalamove_quotation_response, :text, default: ''
    add_column :spree_shipments, :lalamove_order_response, :text, default: ''
  end
end
