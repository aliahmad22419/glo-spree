class AddFieldToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :recipient_email_link, :string
  end
end
