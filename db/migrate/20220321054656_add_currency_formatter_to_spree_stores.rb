class AddCurrencyFormatterToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :currency_formatter, :boolean, default: false
  end
end
