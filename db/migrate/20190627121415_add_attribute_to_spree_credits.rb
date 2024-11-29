class AddAttributeToSpreeCredits < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_store_credits, :reason, :string
    add_column :spree_store_credits, :type, :string
    add_column :spree_store_credits, :transaction_id, :string
    add_column :spree_store_credits, :balance, :decimal, precision: 8, scale: 2, null: false
    add_column :spree_store_credits, :payment_mode, :integer
  end
end
