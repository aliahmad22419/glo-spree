class AddHideShippingMethodToSpreeShippingMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :hide_shipping_method, :boolean, default: false
  end
end
