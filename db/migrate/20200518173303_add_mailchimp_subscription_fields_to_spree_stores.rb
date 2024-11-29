class AddMailchimpSubscriptionFieldsToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :subscription_title, :string
    add_column :spree_stores, :subscription_text, :text
  end
end
