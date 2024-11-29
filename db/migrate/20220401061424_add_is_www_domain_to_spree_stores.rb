class AddIsWwwDomainToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :is_www_domain, :boolean, default: false
  end
end
