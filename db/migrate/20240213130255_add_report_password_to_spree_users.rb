class AddReportPasswordToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :user_report_password, :string, default: nil
  end
end
