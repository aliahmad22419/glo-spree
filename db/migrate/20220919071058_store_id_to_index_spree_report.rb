class StoreIdToIndexSpreeReport < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_reports, :store_id
    add_index :spree_reports, [:store_id,:id]
  end
end
