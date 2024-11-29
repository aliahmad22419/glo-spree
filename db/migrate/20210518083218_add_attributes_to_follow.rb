class AddAttributesToFollow < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_follows, :website, :string
    add_column :spree_follows, :instagram, :string
    add_column :spree_follows, :country_name, :string
  end
end
