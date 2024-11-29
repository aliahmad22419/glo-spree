# This migration comes from spree (originally 20220103082046)
class AddStatusAndMakeActiveAtToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    change_column_default :spree_products, :status, 'draft'
    add_index :spree_products, :status
    add_index :spree_products, %i[status deleted_at]
  end
end
