class ChangeSupportedCurrenciesTypeToArrayInSpreeClients < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_clients, :supported_currencies, :text, array: true, default: "{}", using: "(string_to_array(supported_currencies, ','))"
  end
end
