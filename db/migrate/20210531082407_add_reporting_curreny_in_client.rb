class AddReportingCurrenyInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :reporting_currency, :string, default: "USD"
  end
end
