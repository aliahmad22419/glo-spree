class AddBccToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :bcc_emails, :text, default: ''
  end
end
