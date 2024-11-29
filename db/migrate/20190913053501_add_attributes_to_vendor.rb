class AddAttributesToVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :landing_page_url, :string
    add_column :spree_vendors, :additional_emails, :text
    add_column :spree_customizations, :store_ids, :text,  array: true , default: []
  end
end
