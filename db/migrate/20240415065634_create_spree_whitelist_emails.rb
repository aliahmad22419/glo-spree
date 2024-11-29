class CreateSpreeWhitelistEmails < ActiveRecord::Migration[6.1]
  def change
    create_table :spree_whitelist_emails do |t|
      t.string :email
      t.references :client, index: true
      t.integer :status, default: 0
      t.boolean :verification_sent, default: false
      t.integer :user_id, null: false
      t.string :service_type
      t.timestamps
    end
  end
end
