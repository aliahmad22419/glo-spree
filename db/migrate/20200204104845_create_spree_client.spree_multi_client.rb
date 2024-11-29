# This migration comes from spree_multi_client (originally 20200203110243)
class CreateSpreeClient < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_clients do |t|
      t.string :name
      t.string :email
    end
  end
end
