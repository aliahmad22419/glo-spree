class CreateSpreeLinkSource < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_link_sources do |t|
      t.integer :state, default: 0
      t.integer :payment_method_id
      t.integer :user_id
      t.string :gateway_reference
      t.string :url
      t.datetime :expires_at
      t.jsonb :meta
      
      t.timestamps

      t.index [:user_id], name: "index_spree_link_sources_on_user_id"
      t.index [:payment_method_id], name: "index_spree_link_sources_on_payment_method_id"
    end
  end
end
