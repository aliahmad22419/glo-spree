class AddPrefixAndSuffixToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :prefix, :string, default: ''
    add_column :spree_products, :suffix, :string, default: ''
  end
end
