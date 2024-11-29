class AddColumnCustomJscToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :custom_js, :text, default: ""
  end
end
