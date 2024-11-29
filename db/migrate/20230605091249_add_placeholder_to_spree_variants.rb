class AddPlaceholderToSpreeVariants < ActiveRecord::Migration[5.2]
  def up
    add_column :spree_variants, :placeholder, :string
    Spree::Variant.find_each do |variant|
      variant.update_column(:placeholder, variant.options_text.presence || variant.sku)
    end
  end
  
  def down
    remove_column :spree_variants, :placeholder
  end
end
