class AddClientReferenceToWidget < ActiveRecord::Migration[5.2]
  def change
    add_reference :spree_embed_widgets, :client, index: true
    remove_column :spree_embed_widgets, :vendor_id
  end
end
