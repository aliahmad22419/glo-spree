class RemoveDefaultCountryKindToSpreeZones < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:spree_zones, :kind, nil)
  end
end
