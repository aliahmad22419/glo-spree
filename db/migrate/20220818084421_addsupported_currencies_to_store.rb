class AddsupportedCurrenciesToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :supported_currencies, :text, array: true, default: []
  end
end