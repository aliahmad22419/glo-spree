class AddHideFromSearchToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :hide_from_search, :boolean, default: false
  end
end
