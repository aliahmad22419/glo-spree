class AddBurgerMenuThemeToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :burger_menu_theme, :boolean, default: false
    add_column :spree_stores, :contact_number, :string
    add_column :spree_stores, :mail_to, :string
    add_column :spree_stores, :customer_service_url, :string
  end
end
