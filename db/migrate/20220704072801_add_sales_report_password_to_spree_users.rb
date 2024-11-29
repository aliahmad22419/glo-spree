class AddSalesReportPasswordToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :sales_report_password, :string
    add_column :spree_vendors, :sales_report_password, :string
  end
end
