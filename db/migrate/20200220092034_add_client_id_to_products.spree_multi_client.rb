# This migration comes from spree_multi_client (originally 20200220091824)
class AddClientIdToProducts < ActiveRecord::Migration[5.2]
  def change
    table_names = %w[
      products
    ]
  
    table_names.each do |table_name|
      add_reference "spree_#{table_name}", :client, index: true
    end
  end
end
