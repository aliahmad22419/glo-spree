class AddSaleDatesToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :sale_start_date, :datetime
    add_column :spree_products, :sale_end_date, :datetime
    add_column :spree_products, :on_sale, :boolean, default: false
  end
end
