class AddStoreIdsToShippingMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :store_ids, :text,  array: true , default: []
    Spree::ShippingMethod.all.each{|ship| ship.update_column(:store_ids, ship.client.stores.ids)}
  end
end
