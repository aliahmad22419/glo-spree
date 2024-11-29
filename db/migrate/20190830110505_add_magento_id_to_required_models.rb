class AddMagentoIdToRequiredModels < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :magento_id, :integer
    add_column :spree_addresses, :magento_id, :integer
    add_column :spree_stores, :magento_id, :integer
    add_column :spree_taxons, :magento_id, :integer
    add_column :spree_products, :magento_id, :integer
    add_column :spree_vendors, :magento_id, :integer
    # add_column :spree_imag, :magento_id, :integer
  end
end
