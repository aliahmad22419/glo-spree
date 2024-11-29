class AddInvoiceColumnsInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :invoice_company_name, :string, default: ""
    add_column :spree_stores, :invoice_company_address, :text, default: ""
    add_column :spree_stores, :invoice_company_reg_number, :string, default: ""
  end
end
