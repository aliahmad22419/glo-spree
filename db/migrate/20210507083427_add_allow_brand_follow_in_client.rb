class AddAllowBrandFollowInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :allow_brand_follow, :boolean, default: false
  end
end
