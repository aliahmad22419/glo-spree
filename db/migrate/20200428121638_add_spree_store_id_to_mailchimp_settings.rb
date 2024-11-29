class AddSpreeStoreIdToMailchimpSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :mailchimp_settings, :store_id, :integer
  end
end
