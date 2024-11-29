class AddTaxlabelsToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :included_tax_label, :string
    add_column :spree_stores, :excluded_tax_label, :string
  end
end
