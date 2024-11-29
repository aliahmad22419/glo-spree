# This migration comes from spree_wallet (originally 20130719124429)
class AddIndexesOnSpreeStoreCreditsFieldsTypeAndUserId < ActiveRecord::Migration[4.2]
  def change
    add_index :spree_store_credits, :type, name: "index_type_on_spree_store_credits"
    add_index :spree_store_credits, :user_id, name: "index_user_id_on_spree_store_credits"
  end
end
