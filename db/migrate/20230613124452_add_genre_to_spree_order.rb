class AddGenreToSpreeOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :spo_genre, :string
  end
end
