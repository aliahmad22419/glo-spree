class AddPrefixAndSuffixToSpreeStores < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_stores, :prefix, :string, default: '', null: true
    add_column :spree_stores, :suffix, :string, default: '', null: true
  end
end
