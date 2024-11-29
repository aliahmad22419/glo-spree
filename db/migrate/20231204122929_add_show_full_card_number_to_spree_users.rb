class AddShowFullCardNumberToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :show_full_card_number, :boolean, default: false
  end
end
