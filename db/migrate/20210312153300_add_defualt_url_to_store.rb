class AddDefualtUrlToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :default_url, :string
  end
end
