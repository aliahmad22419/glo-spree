# This migration comes from spree_mailchimp_ecommerce (originally 20190425131218)
class AddMailchimpCartStatusToOrder < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_orders, :mailchimp_cart_created, :boolean
    add_column :spree_orders, :mailchimp_campaign_id, :string
  end
end
