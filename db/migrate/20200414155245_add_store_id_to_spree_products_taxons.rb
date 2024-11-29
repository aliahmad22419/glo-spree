class AddStoreIdToSpreeProductsTaxons < ActiveRecord::Migration[5.2]
  def change
    add_reference :spree_products_taxons, :store, index: true
  end
end
