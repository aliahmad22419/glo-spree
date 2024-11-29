class AddFinanceReportToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :enable_finance_report, :boolean, default: false
    add_column :spree_stores, :finance_report_to, :string
    add_column :spree_stores, :finance_report_cc, :string
  end
end
