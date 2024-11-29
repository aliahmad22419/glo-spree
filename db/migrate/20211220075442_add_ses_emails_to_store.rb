class AddSesEmailsToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :ses_emails, :boolean, :default => false
  end
end
