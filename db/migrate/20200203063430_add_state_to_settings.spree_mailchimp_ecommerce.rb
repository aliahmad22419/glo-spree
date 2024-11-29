# This migration comes from spree_mailchimp_ecommerce (originally 20190917095127)
class AddStateToSettings < SpreeExtension::Migration[4.2]
  def change
    add_column :mailchimp_settings, :state, :string, default: 'inactive'
  end
end
