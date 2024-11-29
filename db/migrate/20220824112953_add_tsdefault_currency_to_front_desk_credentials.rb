class AddTsdefaultCurrencyToFrontDeskCredentials < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_front_desk_credentials, :tsdefault_currency, :string
  end
end
