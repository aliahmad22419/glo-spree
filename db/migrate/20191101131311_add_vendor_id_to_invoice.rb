class AddVendorIdToInvoice < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_bookkeeping_documents, :vendor_id, :integer
  end
end
