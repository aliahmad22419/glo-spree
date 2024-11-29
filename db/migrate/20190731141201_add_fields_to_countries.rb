class AddFieldsToCountries < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_countries, :region_required, :boolean, default: false
  end
end
