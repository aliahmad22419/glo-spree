class AddShowBrandNameToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :show_brand_name, :boolean, default: false
  end
end
