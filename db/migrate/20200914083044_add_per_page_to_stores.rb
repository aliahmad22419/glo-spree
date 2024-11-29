class AddPerPageToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :per_page, :integer, default: 24
  end
end
