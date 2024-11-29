class AddColumnsToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :sales_report_password, :string, default: nil
    add_column :spree_stores, :schedule_report, :integer, default: 0
  end
end
