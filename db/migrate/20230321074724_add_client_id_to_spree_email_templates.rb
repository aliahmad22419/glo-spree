class AddClientIdToSpreeEmailTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_email_templates, :client_id, :integer
  end
end
