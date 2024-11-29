# This migration comes from spree_multi_client (originally 20200227080542)
class AddClientIdToCurrency < ActiveRecord::Migration[5.2]
  def change
    table_names = %w[
      currencies
      pages
    ]
  
    table_names.each do |table_name|
      add_reference "spree_#{table_name}", :client, index: true
    end
  end
end
