# This migration comes from spree_print_invoice (originally 20140123094547)
class AddInvoiceDetailsToSpreeOrders < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_orders, :invoice_number, :integer
    add_column :spree_orders, :invoice_date, :date
  end
end
