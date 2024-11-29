class AddStartDateConfigToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :fulfilment_start_date, :date
    add_column :spree_stores, :allow_fulfilment, :boolean, default: false
  end
end
