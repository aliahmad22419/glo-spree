class AddMissingColumnsForGivex < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_givex_cards, :customer_first_name, :string
    add_column :spree_givex_cards, :customer_last_name, :string
    add_column :spree_stores, :supported_locale, :string, default: "en"
    add_column :spree_line_items, :show_gft_card_value, :boolean, default: false
  end
end
