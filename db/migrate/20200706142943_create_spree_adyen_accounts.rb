class CreateSpreeAdyenAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_adyen_accounts do |t|
      t.string :account_code
      t.string :account_holder_code
      t.references :vendor

      t.timestamps
    end
  end
end
