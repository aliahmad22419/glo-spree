class AddStateInUser < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :state, :string, default: 'createpayment'
  end
end
