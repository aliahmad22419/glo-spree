class AddSabreReferenceCodeToSpreeStores < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_stores, :sabre_reference_code, :string
  end
end
