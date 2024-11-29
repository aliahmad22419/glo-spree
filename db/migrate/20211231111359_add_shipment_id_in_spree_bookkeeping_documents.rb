class AddShipmentIdInSpreeBookkeepingDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_bookkeeping_documents, :shipment_id, :integer
  end
end
