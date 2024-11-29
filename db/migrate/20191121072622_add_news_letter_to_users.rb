class AddNewsLetterToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :news_letter, :boolean, default: false
  end
end
