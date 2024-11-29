class AddUrlKeyAttributeToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :url_key, :string, default: ''
  end
end
