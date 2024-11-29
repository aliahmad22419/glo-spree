class AddReportingColumnsToSpreeClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :timezone, :string, default: 'Europe/London'
    add_column :spree_clients, :reporting_from_email_address, :string
  end
end
