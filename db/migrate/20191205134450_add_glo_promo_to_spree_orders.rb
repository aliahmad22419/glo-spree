class AddGloPromoToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :glo_promo, :boolean, default: false
  end
end
