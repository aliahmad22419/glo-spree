# This migration comes from spree_mailchimp_ecommerce (originally 20190910090133)
class AddAccountNameToMailchimpSetting < SpreeExtension::Migration[4.2]
  def change
    add_column :mailchimp_settings, :mailchimp_account_name, :string
  end
end
