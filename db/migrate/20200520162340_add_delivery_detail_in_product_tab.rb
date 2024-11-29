class AddDeliveryDetailInProductTab < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :delivery_details, :text, default: ""
  end
end
