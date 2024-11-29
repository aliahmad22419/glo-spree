class AddIdentityTypeAndMetaToSpreeWhitelistEmails < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_whitelist_emails, :identity_type, :integer, default: 0
    add_column :spree_whitelist_emails, :domain, :string, default: ""
    add_column :spree_whitelist_emails, :recipient_email, :string, default: ""
    add_column :spree_whitelist_emails, :meta, :jsonb, default: {}
  end
end
