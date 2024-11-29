class AddEnableClientDefaultTaxToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :enable_client_default_tax, :boolean, default: false
  end
end
