class AddTenantToTaggings < ActiveRecord::Migration[5.2]
  def self.up
    add_column :spree_taggings, :tenant, :string, limit: 128
    add_index :spree_taggings, :tenant unless index_exists? :spree_taggings, :tenant
  end

  def self.down
    remove_index :spree_taggings, :tenant
    remove_column :spree_taggings, :tenant
  end
end
