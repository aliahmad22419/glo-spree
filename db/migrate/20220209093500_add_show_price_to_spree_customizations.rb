class AddShowPriceToSpreeCustomizations < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_customizations, :show_price, :boolean, default: false
  end
end
