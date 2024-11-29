# This migration comes from spree_mailchimp_ecommerce (originally 20191003145633)
class AddEmailToSettings < SpreeExtension::Migration[4.2]
  def change
    add_column :mailchimp_settings, :mailchimp_store_email, :string
  end
end
