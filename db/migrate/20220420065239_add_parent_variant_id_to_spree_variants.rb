class AddParentVariantIdToSpreeVariants < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_variants, :parent_variant_id, :integer
  end
end
