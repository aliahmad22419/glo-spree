class AddCountrySpecificConfigToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :country_specific, :boolean, default: false
  end
end
