class AddIntimationEmailsToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :intimation_emails, :string
  end
end
