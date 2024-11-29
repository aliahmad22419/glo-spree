class SetDefaultValesOfDeliveries < ActiveRecord::Migration[5.2]
  def change
    change_column_default(
        :spree_products,
        :local_area_delivery,
        0.0
    )
    change_column_default(
        :spree_products,
        :wide_area_delivery,
        0.0
    )
  end
end
