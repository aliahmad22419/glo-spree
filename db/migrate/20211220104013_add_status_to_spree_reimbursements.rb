class AddStatusToSpreeReimbursements < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_reimbursements, :status, :integer, :default => 1
  end
end
