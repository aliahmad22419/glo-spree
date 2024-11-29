class AddOldInvoiceToSpreeBookkeepingDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_bookkeeping_documents, :old_invoice, :boolean
  end
end
