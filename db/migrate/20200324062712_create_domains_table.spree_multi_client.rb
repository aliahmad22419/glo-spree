# This migration comes from spree_multi_client (originally 20200324062154)
class CreateDomainsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_domains do |t|
      t.string :name
      t.integer :client_id
    end
  end
end
