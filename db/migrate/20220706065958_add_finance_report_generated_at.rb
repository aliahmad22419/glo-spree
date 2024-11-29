class AddFinanceReportGeneratedAt < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :finance_report_generated_at, :datetime
  end
end
