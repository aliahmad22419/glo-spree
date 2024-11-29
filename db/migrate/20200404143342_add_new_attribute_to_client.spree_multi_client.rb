# This migration comes from spree_multi_client (originally 20200404142943)
class AddNewAttributeToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :supported_currencies, :text
  end
end
