class AddAttributeInProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :digital_service_provider, :string, default: ''
  end
end
