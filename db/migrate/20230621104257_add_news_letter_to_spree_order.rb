class AddNewsLetterToSpreeOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :news_letter, :boolean, default: false
  end
end
