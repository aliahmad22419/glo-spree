class AddVaidationAttributeToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :product_validations, :text, array: true, default: []
    add_column :spree_clients, :number_of_images, :integer, default: 0
  end
end
