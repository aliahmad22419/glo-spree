class AddAttributesToSpreeVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :email, :string
    add_column :spree_vendors, :contact_name, :string
    add_column :spree_vendors, :enabled, :boolean
    add_column :spree_vendors, :page_enabled, :boolean
    add_column :spree_vendors, :phone, :string
    add_column :spree_vendors, :vacation_mode, :boolean
    add_column :spree_vendors, :vacation_start, :datetime
    add_column :spree_vendors, :vacation_end, :datetime
    add_column :spree_vendors, :bill_address_id, :integer
    add_column :spree_vendors, :ship_address_id, :integer
    add_column :spree_vendors, :conf_contact_name, :string
    add_column :spree_vendors, :banner_image, :string
    add_column :spree_vendors, :landing_page_title, :string
    add_column :spree_vendors, :enabled_google_analytics, :string
    add_column :spree_vendors, :google_analytics_account_number, :string
    add_column :spree_vendors, :description, :text
    add_column :spree_vendors, :sku, :string
  end
end
