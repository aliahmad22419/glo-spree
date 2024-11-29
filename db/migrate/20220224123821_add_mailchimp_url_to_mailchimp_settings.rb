class AddMailchimpUrlToMailchimpSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :mailchimp_settings, :mailchimp_url, :string
  end
end
