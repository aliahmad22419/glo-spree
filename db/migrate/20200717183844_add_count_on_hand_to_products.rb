class AddCountOnHandToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :count_on_hand, :integer
  end
end
